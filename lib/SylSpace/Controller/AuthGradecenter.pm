#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthGradecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use lib '../..';

use SylSpace::Model::Model qw(userexists bioiscomplete);
use SylSpace::Model::Grades qw(authgrade2hash);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/auth/gradecenter' => sub {
  my $c = shift;
  my $uemail = $c->session->{uemail};
  userexists($uemail) or die "User does not exist!\n";
  (bioiscomplete($uemail)) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/bioform');

  my $allgrades= authgrade2hash( $uemail );

  $c->stash( allgrades => $allgrades, uemail => $uemail );
};

1;

################################################################

__DATA__

@@ authgradecenter.html.ep

<% use SylSpace::Model::Controller qw(mkdatatable); %>

%title 'grade center';
%layout 'student';

<main>

<h3> Latest Grades </h3>

  <%== mkdatatable('finalgradebrowser') %>

  <% if (defined($allgrades)) { %>
  <table class="table" style="width: auto !important; margin:2em;" id="finalgradebrowser">
     <%== showfinalgrades($allgrades,$uemail) %>
  </table>
  <% } else { %>
      <p> No grade data posted just yet </p>
  <% } %>



<h3> All Past Grades </h3>

  <%== mkdatatable('allgradebrowser') %>

  <% if (defined($allgrades)) { %>
  <table class="table" style="width: auto !important; margin:2em;" id="allgradebrowser">
     <%== showallgrades($allgrades) %>
  </table>
  <% } else { %>
      <p> No grade data posted just yet </p>
  <% } %>

</main>

  <%
  use Digest::MD5 qw(md5_base64); 
  use SylSpace::Model::Controller qw(btn epochtwo mkdatatable); 
  use SylSpace::Model::Model qw(isshared); 

  sub showfinalgrades {
    my ($allgrades,$uemail)= @_;
    my $rs= "";	## table format
    $rs.= "<thead> <tr> <th>Task</th> <th>Author</th> <th>Grade</th> <th>Share Result</th> </tr> </thead>\n";

    $rs .= "<tbody>\n";
    foreach my $hw (@{$allgrades->{hw}}) {
      foreach my $st (@{$allgrades->{author}}) {
	$rs.= "<tr> <th> $hw </th> <th> ".md5_base64($st)." </th>\n";
	$rs.= "<td style=\"text-align:center\">".($allgrades->{grade}->{$st}->{$hw}||"-")."</td>";
	$rs.= "<td style=\"text-align:center\"> ";
	$rs.= isshared($uemail,$st,$hw)? btn("shareresult?f=$hw&author=$st&unshare=1", 'unshare','btn-danger btn-xs') : btn("shareresult?f=$hw&author=$st&unshare=0", 'share','btn-info btn-xs');
      }
      $rs.= "</td></tr>\n";
    }
    $rs .= "</tbody>\n";

    return $rs;
  }

  sub showallgrades {
    my $allgrades= shift;
    my $rs= "";	## list format
    $rs.= "<thead> <tr> <th> Task </th> <th> Author </th> <th> Grade </th> <th> Epoch </th> <th> GMT </th> </tr> </thead>\n";
    $rs .= "<tbody>\n";

    foreach (split(/\n/, $allgrades->{record})) {
      my ($tskn, $author, $grd, $tma, $gmt)=split(/\t/, $_);
      $rs.= "<tr> <td>$tskn</td> <td>".md5_base64($author)."</td> <td style=\"text-align:center\"> $grd </td> <td> ".epochtwo($tma)." </td> <td> $gmt </td> </tr>";
    }
    $rs .= "</tbody>\n";

    return $rs;
  }  

  %>

