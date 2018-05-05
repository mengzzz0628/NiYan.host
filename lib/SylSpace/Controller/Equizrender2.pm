#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Equizrender2;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use Digest::MD5 qw(md5_base64);
use File::Glob qw(bsd_glob);
use strict;

use SylSpace::Model::Controller qw(global_redirect);
use SylSpace::Model::Utils qw(_getvar);
use SylSpace::Model::Files qw(findprice);
use SylSpace::Model::Model qw(equizrender2);

################################################################

get '/equizrender2' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  # students can run this, too.  sudo( $course, $c->session->{uemail} );
  ## we allow students to run expired equizzes (if they know the names);  feature or bug

  my $equizname=$c->req->query_params->param('f');
  my $author=$c->req->query_params->param('author');
  my $cururl=$c->req->url->to_abs;
  my $callbackurl= $cururl->base."/equizgrade2";
  my $uemail=$c->session->{uemail};

  my $topay="paid";
  if (($author ne $uemail) and !(-e bsd_glob(_getvar()."/users/$uemail/equizzes/$author\~$equizname\~paid"))) { 
    $topay= findprice(_getvar()."/users/$author/equizzes/$equizname");
    ( $topay>0 ) and ($topay="unpaid");
  }

  my $r = equizrender2($author, $equizname, $uemail, $topay, $callbackurl);

  $c->stash( content => $r,
	     quizname => $equizname,
	     template => 'equizrender' );
};

1;

################################################################

__DATA__

@@ equizrender2.html.ep

%title 'take an equiz';
%layout 'both';
    <script type="text/javascript" async src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-MML-AM-CHTML"></script>
    <script type="text/javascript"       src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_HTML-full"></script>

  <script type="text/javascript" src="/js/eqbackend.js"></script>
  <link href="/css/eqbackend.css" media="screen" rel="stylesheet" type="text/css" />
  <link href="/css/input.css" media="screen" rel="stylesheet" type="text/css" />

  <script type="text/x-mathjax-config">
  MathJax.Hub.Register.StartupHook("TeX Jax Ready",function () {
    MathJax.InputJax.TeX.Definitions.number =
      /^(?:[0-9]+(?:,[0-9]{3})*(?:\.[0-9]*)*|\.[0-9]+)/
    });
  </script>

<main>

 <!-- Quiz: <%= $quizname %> -->

<%== $content %>

</main>

