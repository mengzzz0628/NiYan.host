#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Equizgrade2;
use Mojolicious::Lite;
use File::Glob qw(bsd_glob);
use File::Touch;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(equizgrade equizanswerrender bioiscomplete);
use SylSpace::Model::Grades qw(storegradeequiz2);
use SylSpace::Model::Controller qw(global_redirect btn);
use SylSpace::Model::Files qw(findprice);
my $var= SylSpace::Model::Utils::_getvar();

################################################################

my $equizgrade2 = sub {
  my $c = shift;
  my $uemail = $c->session->{uemail};
  (bioiscomplete($uemail)) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/bioform');
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $params= $c->req->query_params; 
  my $author= ($params->param('author'));
  my $filename = $params->param('f');

  if (($author ne $uemail) and !(-e bsd_glob("$var/users/$uemail/equizzes/$author\~$filename\~paid"))) { 
    my $topay= findprice("$var/users/$author/equizzes/$filename");
    ( $topay>0 ) and die "You haven't pay for the equiz yet. Please go back and pay \$$topay first.";
    ( $topay==0 ) and (touch("$var/users/$uemail/equizzes/$author\~$filename\~paid"));
  }


  my $result= equizgrade('', $c->session->{uemail}, $c->req->body_params->to_hash);
  ## _storegradeequiz( $course, $uemail, $gradename, $eqlongname, $time, "$score / $i" );
  storegradeequiz2( $author, $uemail, $filename, $result->[3], $result->[1]." / ". $result->[0] );

  $c->stash( eqanswer => equizanswerrender($result) );

};

get '/equizgrade2' => $equizgrade2;
post '/equizgrade2' => $equizgrade2;

1;

################################################################

__DATA__

@@ equizgrade2.html.ep

%title 'show equiz results';
%layout 'both';

<main>

<h1>Equiz Results</h1>

    <%== $eqanswer %>

</main>

