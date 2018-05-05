#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthFiledelete;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(autheqdelete);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

get '/auth/filedelete' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $fname= $c->req->query_params->param('f');
  my $author= $c->req->query_params->param('author');
  ($author eq $c->session->{uemail}) or die "You can't delete other's equiz\n";
  autheqdelete( $author, $fname);

  return $c->flash( message=> "completely deleted file $fname" )->redirect_to('/auth/goclass');
};

1;
