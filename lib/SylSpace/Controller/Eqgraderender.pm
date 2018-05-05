#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Eqgraderender;
use Mojolicious::Lite;
use File::Glob qw(bsd_glob);
use File::Touch;
use Perl6::Slurp;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(equizgrade equizanswerrender bioiscomplete isshared);
use SylSpace::Model::Grades qw(storegradeequiz2);
use SylSpace::Model::Controller qw(global_redirect btn);
use SylSpace::Model::Files qw(findprice);
my $var= SylSpace::Model::Utils::_getvar();

################################################################

my $eqgraderender = sub {
  my $c = shift;
  my $uemail = $c->session->{uemail};
  (bioiscomplete($uemail)) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/bioform');
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $params= $c->req->query_params; 
  my $semail= ($params->param('s'));
  my $filename = $params->param('f');
  my $sfilename = $filename; $sfilename =~ s{(.*)\.\d+\.eanswer.*}{$1};

  (isshared($semail,$uemail,$sfilename)) or die "The student didn't share his grade with you.\n";
  my $answerpath= "$var/users/$semail/equizzes/$filename";

  my $yamlofinfo= YAML::Tiny->read($answerpath)->[0];

  my $result= equizgrade('', $uemail,$yamlofinfo,1);

  $c->stash( eqanswer => equizanswerrender($result) );

};

get '/eqgraderender' => $eqgraderender;

1;

################################################################

__DATA__

@@ eqgraderender.html.ep

%title 'show equiz results';
%layout 'both';

<main>

<h1>Equiz Results</h1>

    <%== $eqanswer %>

</main>

