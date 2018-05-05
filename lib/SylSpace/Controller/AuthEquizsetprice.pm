#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthEquizsetprice;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Files qw(eqsetprice);
use SylSpace::Model::Controller qw(global_redirect);

################################################################

use Mojo::Date;

get '/auth/equizsetprice' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $params= $c->req->query_params;

  my $author= ($params->param('author'));
  my $filename = $params->param('f');
  ($author eq $c->session->{uemail}) or die "You can't change the price of $filename written by $author";
  my $newprice= ($params->param('price'));
  (defined($newprice) and $newprice>=0) or die "equizsetprice: What's your new price?";

  eqsetprice($c->session->{uemail},$filename,$author,$newprice);

  my $msg= $author." set '".$filename."' price to \$$newprice";

  $c->flash(message => $msg)->redirect_to("/auth/goclass");
};


1;

