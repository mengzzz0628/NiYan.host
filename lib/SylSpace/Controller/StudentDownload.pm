#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentDownload;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get 'student/download' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

  my $fname=  $c->req->query_params->param('f');
  my $author=  $c->req->query_params->param('author');
  (defined($fname)) or die "need a filename for instructordownload.pm.\n";

  $c->stash( filename => $fname, author => $author );
};

1;

################################################################

__DATA__

@@ studentdownload.html.ep

%title 'download a file';
%layout 'student';

<main>

<meta http-equiv="refresh" content="1;url=silentdownload?f=<%=$filename%>&author=<%=$author%>">

Your file content will download asap.  If not, click <a href="silentdownload?f=<%=$filename%>&author=<%=$author%>">silentdownload?f=<%=$filename%>&author=<%=$author%></a>.

</main>
