#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthDownload;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get 'auth/download' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

  my $fname=  $c->req->query_params->param('f');
  (defined($fname)) or die "need a filename for instructordownload.pm.\n";

  my $author= $c->req->query_params->param('author');
  ($author eq $c->session->{uemail}) or die "You can't download other's equiz\n";

  $c->stash( filename => $fname, author => $author );
};

1;

################################################################

__DATA__

@@ authdownload.html.ep

%title 'download a file';
%layout 'student';

<main>

<meta http-equiv="refresh" content="1;url=silentdownload?f=<%=$filename%>&author=<%=$author%>">

Your file content will download asap.  If not, click <a href="/auth/silentdownload?f=<%=$filename%>&author=<%=$author%>">silentdownload?f=<%=$filename%>&author=<%=$author%></a>.

</main>
