#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthSilentdownload;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Utils qw(_getvar);
use SylSpace::Model::Files qw(longfilename);
use SylSpace::Model::Controller qw(global_redirect);

################################################################

get 'auth/silentdownload' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

  my $fname = $c->req->query_params->param('f');
  my $author = $c->req->query_params->param('author');
  ($author eq $c->session->{uemail}) or die "You can't download other's equiz\n";

  my $longfilename;
  if (($fname =~ /.zip$/) && ($fname =~ m{/tmp/})) {
    $longfilename = $fname;
  } else {
    $fname =~ s{.*/}{};
    $longfilename= _getvar()."/users/$author/equizzes/$fname";
    (-l ($longfilename."~author=$author")) and $longfilename=readlink($longfilename."~author=$author");
    (-e $longfilename) or die "file $longfilename is not retrievable: $!\n";
  }

  return $c->render_file('filepath' => $longfilename);
};
