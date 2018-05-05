#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthEdit;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled);
use SylSpace::Model::Files qw(autheqread);
use SylSpace::Model::Controller qw(global_redirect);

################################################################

get '/auth/edit' => sub {
  my $c = shift;
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $filename= $c->req->query_params->param('f');
  my $author= $c->req->query_params->param('author');
  ($c->session->{uemail} eq $author) or die "You have no access to the source code of $filename written by $author";

  my $filecontent= autheqread($c->session->{uemail}, $filename, $author );
  my $filelength= length($filecontent);

  $filecontent =~ s/\r\n/\r/g;
  $filecontent =~ s/\r/\n/g;

  use Digest::MD5 qw(md5_hex);
  $c->stash( filelength => $filelength, filename => $filename, filecontent => $filecontent, fingerprint => md5_hex($filecontent), author => $author );
};

1;

################################################################

__DATA__

@@ authedit.html.ep

%title 'edit a file';
%layout 'student';

<style> textarea.textarea {  font-family: monospace;  display:block;  height:80vh;  width:100%;  line-height:16px;  padding:5px;  margin:0px auto;    }</style>


<main>

  <form method="POST" action="editsave">

  <input type="hidden" name="fname" value="<%= $filename %>" />
  <input type="hidden" name="author" value="<%= $author %>" />
  <input type="hidden" name="fingerprint" value="<%= $fingerprint %>" />
  <input type="hidden" name="filelength" value="<%= $filelength %>" />

  <textarea name="content" id="textarea" spellcheck="false" class="textarea"><%= $filecontent %></textarea>

  <script type="text/javascript" src="/js/confirm.js"></script>

  <div class="row top-buffer text-center">
  <div class="col-md-12">
     <button class="btn btn-lg btn-default btn-block btn-danger" name="submitbutton"  type="submit" value="combine" style="font-size:x-large"  onclick="show_alert();">Save Changes</button>
  <p>This will overwrite the original!</p>
  </div> <!--col-md-12-->
  </div> <!--row-->

  </form>

</main>

