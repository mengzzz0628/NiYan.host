#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Model::Grades;

use base 'Exporter';
@ISA = qw(Exporter);

@EXPORT_OK=qw( gradetaskadd gradesave gradesashash gradesasraw gradesfortask2table storegradeequiz storegradeequiz2 authgrade2hash shareresult);


################
use strict;
use common::sense;
use utf8;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;
use File::Glob qw(bsd_glob);

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

################

use lib '../..';

use SylSpace::Model::Model qw(studentlist);

use SylSpace::Model::Utils qw( _getvar _confirmsudoset _burpnew _burpapp _checkemailvalid _checkcname _glob2last _savesudo _restoresudo _setsudo);

my $var= _getvar();

use Perl6::Slurp;
use File::Touch;

################################################################

=pod

=head2 Grading interface, allowing setting and reading grades

=cut

################################################################

## can be done repeatedly without harm
sub gradetaskadd( $course, @hwname ) {
  my $tasklistfile="$var/courses/$course/tasklist";
  _confirmsudoset($course);

  my %existing;
  if (-e $tasklistfile) { foreach (slurp($tasklistfile)) { ($_ eq "\n") or chomp; $existing{$_}= 1; } }
foreach (keys %existing) {print ">>$_<<"};
  my @addhw;
  foreach ( @hwname ) {
    chomp;
print "\n>$_<\n>".(defined($existing{$_}))."<\n";
    ($existing{$_}) and next;  ## just ignore the task if it already is in file
    push(@addhw, $_);
  }

  (@addhw) and _burpapp( $tasklistfile, "\n".join("\n",@addhw));
  return $#addhw+1;
}

sub gradesasraw( $course ) {
  (-e "$var/courses/$course/grades") or return "no grades yet";
  return slurp("$var/courses/$course/grades");
}


## no uemail means that 
sub gradesashash( $course, $uemail=undef ) {
  ## as instructor, just leave uemail blank and you get all grades;
  ## otherwise, with an email, you only get your own grades

  $course= _checkcname( $course );

  (-e "$var/courses/$course/grades") or return;
  my @gradelist= slurp("$var/courses/$course/grades");
  if (defined($uemail)) {
    @gradelist= grep(/$uemail/, @gradelist);  ## faster...we just do it for 1 student
  } else {
    $course= _confirmsudoset($course);  ## make sure
  }
  ## hw stays in order!
  my (%hw,@hw);  foreach (slurp("$var/courses/$course/tasklist")) { chomp; $hw{$_}=1; push(@hw, $_); }

  my (%col, %row, $gradecell, $timestamp);
  foreach (@gradelist) {
    s/[\r\n]//;
    (defined($_)) or die "something is wrong.  I do not see a line in gradelist.\n";
    ($_ eq "") and next;
    my ($uem, $tskn, $grd, $tma)=split(/\t/, $_);
    (defined($tma)) or die "something is wrong.  In '$_', I cannot find a good timestamp as the fourth field";
    ($tma >= 1493749426) or die "corrupted homework file. time is $tma, which is long ago!\n";

    $col{$uem}= $uem; ## unregistered students can have homeworks, so no check against registered list
    $row{$tskn}= $tskn;
    $hw{$tskn} or die "unknown homework '$tskn'\n".slurp("$var/courses/$course/tasklist")."\n";
    $gradecell->{$uem}->{$tskn}= $grd;  ## use the last time we got a grade for this task;  ignore earlier grades
    $timestamp->{$uem}->{$tskn}= $tma;
  }
  my @col= sort keys %col;
  # my @row= sort keys %row;
  ($#col == (-1)) and return;

  use SylSpace::Model::Model qw(studentlist);
  return { hw => \@hw,
	   uemail => (defined($uemail) ? [ $uemail ] : studentlist( $course )),
	   grade => $gradecell, epoch => $timestamp };
}


## entering is easy: just append to a file.  the only complex aspect is that we do not want
## to repeat ourselves; if the grade has not changed, keep the old entry.  note that we may
## have multiple grades on the same homework in the file.  the reader has to be smart enough
## to know that it is the last one that counts;
sub gradesave( $course, $semail, $hwname, $newgrade ) {
  $course= _confirmsudoset( $course );

  my (@semail, @hwname, @newgrade);

  if (ref $semail eq 'ARRAY') {
    (ref $hwname eq 'ARRAY') or die 'gradeadd: either all or none are arrays!';
    (ref $newgrade eq 'ARRAY') or die 'gradeadd: either all or none are arrays!';
    ((scalar @{ $semail }) == (scalar @{ $hwname })) or die "gradeadd: must be the same number of obs";
    ((scalar @{ $semail }) == (scalar @{ $newgrade })) or die "gradeadd: must be the same number of obs";
    @semail= @$semail;
    @hwname= @$hwname;
    @newgrade= @$newgrade;
  } else {
    push(@semail, $semail ); push(@hwname, $hwname); push(@newgrade, $newgrade);
  }

  my %recorded;
  if (-e "$var/courses/$course/grades") {
    foreach (slurp("$var/courses/$course/grades")) {
      my @k= split(/\t/, $_); pop(@k);
      $recorded{join("\t", @k)}=1;
    }
  }

  my %hw;
  if (-e "$var/courses/$course/tasklist") {
    foreach (slurp("$var/courses/$course/tasklist")) { chomp; $hw{$_}=1; }
  }

  my @todo;
  while ($#semail >= 0) {
    my $e= pop(@semail); _checkemailenrolled($e,$course);  ## we could permit recording non-registered students
    my $h= pop(@hwname); ($hw{$h}) or die "cannot add grade for non-existing homework '$h', course $course.";
    my $g= pop(@newgrade); ## grades can be anything
    my $ehg= "$e\t$h\t$g";
    #($recorded{$ehg}) and next;  # problem of this line: Time is not included here. If some one took an equiz several times and got 1/1 0/1 1/1, the second 1/1 cannot replace the 0/1 even if it's newer
    $recorded{$ehg}= 1;
    push(@todo, $ehg."\t".time()."\n");
  }

  (@todo) and _burpapp("$var/courses/$course/grades", join("", @todo));

  return $#todo+1;
}

##
sub gradesfortask2table($course, $task, $author=undef) {
  my @r;
  my $filepath;
  if ($course eq "") {
    defined($author) or die "Who's the author?";
    $filepath = "$var/users/$author/equizzes/$task";
    -e $filepath or die "invalid file path $filepath\n";
    $filepath .= "~grades";
  } else { 
    $filepath = "$var/courses/$course/grades";
    -e $filepath or die "invalid file path $filepath\n";
  }
  
  -e $filepath or return undef;
  open(my $FIN, "<", $filepath) or return;
  if (defined($author)) {  # student equiz
    while (<$FIN>) {
      my @c= split(/\t/, $_);
      push(@r, [ $c[0], $c[1], $c[2] ]);
    }
  } else {		# course equiz
    while (<$FIN>) {
      my @c= split(/\t/, $_);
      ($c[1] eq $task) or next;
      push(@r, [ $c[0], $c[2], $c[3] ]);
    }
  }
  return \@r;
}



sub _checkemailenrolled($e,$course) {
  $e= _checkemailvalid($e);
  (-d "$var/courses/$course/$e") or die "Grades.pm:_checkemailenrolled: $e is not enrolled in $course ($var/courses/$course/$e)\n";
}



##
sub storegradeequiz( $course, $semail, $gradename, $eqlongname, $time, $grade, $optcontentptr=undef ) {
  ## $course= _confirmsudoset( $course );  ## sudo must have been called!

  $course= _checkcname( $course );  ## sudo must have been called!
  _checkemailenrolled($semail,$course);
  ($time > 0) or die "wtf is your quiz time?";
  ($time <= time()) or die "back to the future?!";

  (-d "$var/courses/$course/$semail/files") or die "bad storegradeequiz directory: $var/courses/$course/$semail\n";
  (-w "$var/courses/$course/$semail/files") or die "non-writeable directory:\n";

  ## temporarily allow su privileges to add to grades, too
  _savesudo();
  _setsudo();
  gradetaskadd( $course, $gradename );
  my $rv=gradesave( $course, $semail, $gradename, $grade );
  _restoresudo();

  return $rv;
}

# store grade for student equiz
sub storegradeequiz2( $author, $semail, $equizname, $time, $grade, $optcontentptr=undef ) {

  _checkemailvalid($semail);  ## we could permit recording non-registered students
  (-e "$var/users/$author/equizzes/$equizname") or die "no such equiz\n";
  (-e "$var/users/$author/equizzes/$equizname~grades") or _burpnew("$var/users/$author/equizzes/$equizname~grades","");
  ($time > 0) or die "wtf is your equiz time?";
  ($time <= time()) or die "back to the future?!";

  (-d "$var/users/$author/equizzes") or die "bad storegradeequiz directory: $var/users/$author/equizzes\n";
  (-w "$var/users/$author/equizzes") or die "non-writeable directory:\n";

  _burpapp("$var/users/$author/equizzes/$equizname~grades", "$semail\t$grade\t$time\n");  
  _burpapp("$var/users/$semail/equizzes/grades", "$equizname\t$author\t$grade\t$time\t".gmtime()."\n");  
}

sub authgrade2hash( $uemail ) {
  my (%col, %row, $gradecell, $timestamp, @hw);
  foreach (bsd_glob("$var/users/$uemail/equizzes/*\~paid")) {
    $_ =~ s{^.*equizzes/.*\~(.*)\~paid$}{$1};
    push(@hw,$_);
  }
  my $gradefile = "$var/users/$uemail/equizzes/grades";
  (-e $gradefile) or return;
  foreach (slurp($gradefile)) {
    s/[\r\n]//;
    (defined($_)) or die "something is wrong.  I do not see a line in gradelist.\n";
    ($_ eq "") and next;
    my ($tskn, $author, $grd, $tma)=split(/\t/, $_);
    (defined($tma)) or die "something is wrong.  In '$_', I cannot find a good timestamp as the fourth field";
    ($tma >= 1493749426) or die "corrupted equiz file. time is $tma, which is long ago!\n";

    $col{$author}= $author; ## unregistered students can have homeworks, so no check against registered list
    $row{$tskn}= $tskn;
    $gradecell->{$author}->{$tskn}= $grd;  ## use the last time we got a grade for this task;  ignore earlier grades
    $timestamp->{$author}->{$tskn}= $tma;
  }
  my @col= sort keys %col;
  ($#col == (-1)) and return;

  return { hw => \@hw,
           author => \@col, 
	   grade => $gradecell, epoch => $timestamp,
	   record => scalar slurp($gradefile) };
}

sub shareresult ($uemail, $author, $filename, $unshare) {
  (_checkemailvalid($uemail) and _checkemailvalid($author)) or die "Invalid $uemail / $author.\n";
  (-e "$var/users/$author/equizzes/$filename") or return "$filename does not exist or has been deleted.\n";
  (-e "$var/users/$uemail/equizzes/$author\~$filename\~paid") or die "You have no access to $filename.\n";
  $unshare?
  (unlink("$var/users/$author/equizzes/$filename\~$uemail") and return "Unshared $filename result successfully.\n")
  :(touch("$var/users/$author/equizzes/$filename\~$uemail") and return "Shared $filename result successfully.\n");
}

1;
