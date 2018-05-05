#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthTransacthistory;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userexists showtranslog);

################################################################

get '/auth/transacthistory' => sub {
  my $c = shift;
  my $uemail = $c->session->{uemail};
  userexists($uemail) or die "User does not exist!\n";

  #$c->stash(toprightexit => '<li><a href="/auth/goclass"> <i class="fa fa-sign-out"></i> Exit Course </a></li>');

  $c->stash( translog => showtranslog($uemail) );
};

1;

################################################################

__DATA__

@@ authtransacthistory.html.ep

%title 'transaction center';
%layout 'student';

<main>

<h2> All Previous Transactions </h2>

  <%== displaytranslog( $translog ) %>

</main>

<%
use SylSpace::Model::Controller qw(epochtwo mkdatatable); 
use Digest::MD5 qw(md5_base64); 

sub displaytranslog {
  my $translogptr = shift;
  my $s="";
  foreach (split(/\n/, $translogptr)) {
    my ($ip, $epoch, $gmt, $filename, $amount, $from, $to)=split(/\t/,$_);
    ($amount =~ m/^+/)? ($from = md5_base64($from) and $ip=""): ($to = md5_base64($to));
    $s.= "<tr> <td>$ip</td> <td>".epochtwo($epoch)."</td> <td> $gmt </td> <td> $filename </td> <td> $amount </td> <td>$from</td> <td>$to</td> </tr>";
  };

  return mkdatatable('translogbrowser').<<LOGT;
   <table class="table" id="translogbrowser">
      <thead> <tr> <th>IP</th> <th> Epoch </th> <th> GMT </th> <th> File </th> <th> Amount </th> <th> From </th> <th> To </th> </tr> </thead>
      <tbody>
       $s
     </tbody>
   </table>
LOGT
}
%>

