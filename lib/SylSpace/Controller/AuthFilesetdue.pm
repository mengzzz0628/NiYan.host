#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthFilesetdue;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo tweet tzi equizrender2);
use SylSpace::Model::Files qw(_deepsetdue);
use SylSpace::Model::Controller qw(global_redirect  standard epochof epochtwo);
use SylSpace::Model::Utils qw(_getvar);

################################################################

use Mojo::Date;

get '/auth/filesetdue' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $params= $c->req->query_params;

  my $whendue= ($params->param('dueepoch')) ||
    epochof( $params->param('duedate'), $params->param('duetime'), tzi($c->session->{uemail}) );
  my $author= ($params->param('author'));
  my $filename = $params->param('f');
  ($author eq $c->session->{uemail}) or die "You can't change due time of other's equiz";
  #$c->flash(message => "Preview of $filename")->redirect_to('/equizrender2?f=$filename&author=$author');
  my $preview = equizrender2($author,$filename,$author,"own",$c->req->url->to_abs->base."/auth/goclass");

  if ($preview =~ /<input type="hidden" class="encrypted" name="confidential" value="/) {
    my $r= _deepsetdue( $whendue, _getvar()."/users/$author/equizzes/$filename");
    my $msg= $author." set '".$filename."' due to ".epochtwo( $whendue || 0);

    $c->flash(message => $msg)->redirect_to("/auth/goclass");
  } else {
    $c->stash( preview => $preview );
  }

};


1;

################################################################

__DATA__

@@ authfilesetdue.html.ep

%title 'Invalid equiz';
%layout 'student';

<main>

<h3>Your equiz can't render properly, so it cannot be published. Please go back.</h3>

<%== $preview %>

</main>

