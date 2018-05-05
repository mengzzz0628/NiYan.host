#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthEditsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled);
use SylSpace::Model::Files qw(eqwrites);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

post '/auth/editsave' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $fname= $c->req->params->param('fname');
  my $author= $c->req->params->param('author');
  ($author eq $c->session->{uemail}) or die "You don't have right to edit other's equiz";
  my $content= $c->req->params->param('content');
  $content =~ s/\r\n/\r/g;
  $content =~ s/\r/\n/g;

  use Digest::MD5 qw(md5_hex);
  my $reportaction="unknown";
  if (md5_hex($content) eq $c->req->params->param('fingerprint')) {
    $c->flash( message=> "file $fname was unchanged and thus not updated" );
  } else {
    eqwrites($c->session->{uemail}, $fname, $content, 1);
    $c->flash( message=> "file $fname was changed and thus updated" );
  }

  $c->redirect_to("/auth/goclass");
};

1;
