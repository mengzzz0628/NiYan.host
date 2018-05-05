#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Uploadsave2;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isinstructor tweet seclog);
use SylSpace::Model::Files qw(filewritei answerwrite eqwrites);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################
  # $app    = $app->max_request_size(16777216);

post '/uploadsave2' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  return $c->render(text => 'File is too big for M', status => 200) if $c->req->is_limit_exceeded;

  my $uploadfile = $c->param('file');
  (defined($uploadfile)) or die "confusing not to see an upload file.  please alert webauthor.\n";

  my $filesize = $uploadfile->size;
  my $filename = $uploadfile->filename;
  #  my $filecontents = $uploadfile->asset->{content};  ## could be done more efficiently by working with the diskfile
  my $filecontents = $uploadfile->asset->slurp();  ## could be done more efficiently by working with the diskfile

  # Check file size by instructor type
  ## (isinstructor($course, $c-session->{uemail}) or return $c->render(text => 'File is too big for s', status => 200) if ($filesize>1024*1024*16);

  ($filename =~ m{\.equiz$}i) or die "You file name must end with '.equiz'. Please Go back.";

    ## superfluous tests
    defined($filename) or die "uploadsave error: what is your filename??";
    defined($filecontents) or die "uploadsave error: what are your filecontents??";
    ($filename eq "") and return $c->flash(message=>"please select a file first!")->redirect_to("/auth/goclass");

      my $result= eval { eqwrites($c->session->{uemail},$filename, $filecontents) };
      $@ and die "Problem $result Writing Equiz : '$@'
Uemail: ".($c->session->{uemail})."<br />
Filename: $filename
Filecontents: ".length($filecontents)." bytes.
</pre>
 ";

  $c->flash( message => "squirreled away '$filename' ($filesize bytes)" )->redirect_to("/auth/goclass");
};

1;
