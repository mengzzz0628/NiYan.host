#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentEquizmore;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled tzi);
use SylSpace::Model::Files qw(eqownlists eqlists);
use SylSpace::Model::Grades qw(gradesfortask2table);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/student/equizmore' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $fname=  $c->req->query_params->param('f');
  (defined($fname)) or die "need a filename for equizmore.\n";

  my $detail = eqownlists($course, $c->session->{uemail});
  my $studentuploaded = eqlists($course);
  my $grds4tsk =  gradesfortask2table($course, $fname);
  my $tzii = tzi( $c->session->{uemail} );

  $c->stash( detail => eqownlists($course, $c->session->{uemail}),
	     fname => $fname,
	     grds4tsk =>  gradesfortask2table($course, $fname),
	     tzi => tzi( $c->session->{uemail} ) );
};

1;

################################################################

__DATA__

@@ studentequizmore.html.ep

<% use SylSpace::Model::Controller qw(drawmore epochtwo mkdatatable webbrowser); %>

%title 'more equiz information';
%layout 'student';

  <%== mkdatatable('eqabrowser') %>

<main>

  <%== drawmore($fname, 'equiz', [ 'equizrun', 'view', 'download', 'edit' ], $detail, $tzi, webbrowser($self), $c->session->{uemail}); %>

  <hr />

  <h2> Student Performance </h2>
  <table class="table" id="eqabrowser">
    <thead> <tr> <th> # </th> <th> Student </th> <th> Score </th> <th> Date </th> </tr> </thead>
    <tbody>
      <%== mktbl($grds4tsk) %>
    </tbody>
  </table>

</main>

    <%
    sub mktbl {
      my $rs=""; my $i=0;
      foreach (@{$_[0]}) {
	$rs .= "<tr> <td>".++$i."</td> <td>$_->[0]</td> <td>$_->[1]</td> <td>".epochtwo($_->[2])."</td> </tr>\n";
      }
      return $rs;
    }
    %>
