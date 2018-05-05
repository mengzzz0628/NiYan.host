#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthShareresult;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Grades qw(shareresult);
use SylSpace::Model::Model qw(userexists bioiscomplete);

################################################################

use Mojo::Date;

get '/auth/shareresult' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);
  my $uemail = $c->session->{uemail};
  userexists($uemail) or die "User does not exist!\n";
  (bioiscomplete($uemail)) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/bioform');
  my $params= $c->req->query_params;

  my $author= ($params->param('author'));
  my $filename = $params->param('f');
  my $unshare = $params->param('unshare');
  ($author eq $uemail) and ($c->flash(message => "No sharing with yourself.")->redirect_to("/auth/goclass"));
  
  my $msg= shareresult($uemail, $author, $filename, $unshare);
  $c->flash( message => $msg )->redirect_to('/auth/gradecenter');
  $c->stash(msg => $msg);
};


1;

################################################################

__DATA__

@@ authshareresult.html.ep

%title 'Share Equiz Result';
%layout 'student';

<main>

<%== $msg %>

</main>

