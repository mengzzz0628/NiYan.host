#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthEquizmore;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Utils qw(_getvar);
use SylSpace::Model::Model qw(sudo tzi commentsfortask2table);
use SylSpace::Model::Files qw(eqownlists eqlists _deeplisti);
use SylSpace::Model::Grades qw(gradesfortask2table);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/auth/equizmore' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $filename=  $c->req->query_params->param('f');
  my $author=  $c->req->query_params->param('author');
  (defined($filename)) or die "need a filename for equizmore.\n";
  my $tzii = tzi( $c->session->{uemail} );
  my $detail = _deeplisti(_getvar()."/users/$author/equizzes",$filename);
  #my $detail = ($author eq $c->session->{uemail})? eqownlists($c->session->{uemail}) : ;
  $c->stash( detail => $detail,
	     fname => $filename,
	     grds4tsk =>  gradesfortask2table("", $filename, $author),
	     cmts4tsk =>  commentsfortask2table("", $filename, $author),
	     author => $author,
	     uemail => $c->session->{uemail},
	     tzi => tzi( $c->session->{uemail} ) );
};

1;

################################################################

__DATA__

@@ authequizmore.html.ep

<% use SylSpace::Model::Controller qw(drawmore epochtwo mkdatatable webbrowser btn); 
   use SylSpace::Model::Model qw(isshared);
   use Digest::MD5 qw(md5_base64); %>

%title 'more equiz information';
%layout 'student';

  <%== mkdatatable('eqabrowser') %>
  <%== mkdatatable('msgbrowser') %>

<main>

  <%== drawmore($fname, 'equiz', ($uemail eq $author)? [ 'equizrun', 'view', 'download', 'edit' ] : [ 'equizrun' ], $detail, $tzi, webbrowser($self),$author); %>

  <hr />

  <% if ($author eq $uemail) { %>

  <h2> Student Performance </h2>
  <table class="table" id="eqabrowser">
    <thead> <tr> <th> # </th> <th> Student </th> <th> Score </th> <th> Date </th> <th>Shared Result</th> </tr> </thead>
    <tbody>
      <%== mktbl($grds4tsk,$author,$fname) %>
    </tbody>
  </table>

  <h2> Student Comments </h2>
  <table class="table" id="msgbrowser">
    <thead> <tr> <th> # </th> <th> Student </th> <th> Clarity </th> <th> Difficulty </th> <th> Date </th> <th> Comments </th> </tr> </thead>
    <tbody>
      <%== mktbl2($cmts4tsk,$author,$uemail) %>
    </tbody>
  </table>

  <% } %>

</main>

    <%
    sub mktbl {
      my $rs=""; my $i=0; my $author=$_[1]; my $fname=$_[2];
      foreach (@{$_[0]}) {
	$rs .= "<tr> <td>".++$i."</td> <td>".(($_->[0] eq $author)? $_->[0] : md5_base64($_->[0]))."</td> <td>$_->[1]</td> <td>".epochtwo($_->[2])."</td> <td> ";
	$rs.= isshared($_->[0],$author,$fname)? btn("/eqgraderender?f=$fname\.".$_->[2]."\.eanswer.yml&s=".$_->[0],"view","btn-default btn-xs") : "not available";
	$rs.= "</td> </tr>\n";
      }
      return $rs;
    }
    sub mktbl2 {
      my $rs=""; my $i=0; my ($author,$uemail)=($_[1],$_[2]);
      foreach (@{$_[0]}) {
	$rs .= "<tr> <td>".++$i."</td> <td>".(($_->[0] eq $author)? $_->[0] : md5_base64($_->[0]))."</td> <td>$_->[1]</td> <td>$_->[2]</td> <td>".epochtwo($_->[3])."</td> <td>$_->[4]</td> </tr>\n";
      }
      return $rs;
    }
    %>
