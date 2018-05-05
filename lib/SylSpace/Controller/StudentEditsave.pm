#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentEditsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled);
use SylSpace::Model::Files qw(eqwrites);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

post 'student/editsave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $fname= $c->req->params->param('fname');
  my $author= $c->req->params->param('author');
  ($author eq $c->session->{uemail}) or die "You don't have right to edit $author's equiz since you're not him";
  my $content= $c->req->params->param('content');
  $content =~ s/\r\n/\r/g;
  $content =~ s/\r/\n/g;

  use Digest::MD5 qw(md5_hex);
  my $reportaction="unknown";
  if (md5_hex($content) eq $c->req->params->param('fingerprint')) {
    $c->flash( message=> "file $fname was unchanged and thus not updated" );
  } else {
    eqwrites( $course, $c->session->{uemail}, $fname, $content, 1);
    $c->flash( message=> "file $fname was changed and thus updated" );
  }

  $c->redirect_to("/student/equizmore?f=$fname&author=$author");
};

1;
