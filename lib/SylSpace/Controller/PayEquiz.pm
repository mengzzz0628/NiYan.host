#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::PayEquiz;
use Mojolicious::Lite;
use File::Glob qw(bsd_glob);
use File::Touch;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(bioiscomplete balance transactionlog);
use SylSpace::Model::Controller qw(global_redirect);
use SylSpace::Model::Files qw(findprice);
my $var= SylSpace::Model::Utils::_getvar();

################################################################

post '/payequiz' => sub {
  my $c = shift;
  my $uemail = $c->session->{uemail};
  (bioiscomplete($uemail)) or $c->flash( message => 'You first need to complete your bio!' )->redirect_to('/auth/bioform');
  ($c->req->url->subdomain eq 'auth') or return global_redirect($c);

  my $params= $c->req->query_params;

  my $from= $params->param('from');
  ($from eq $uemail) or die "You can't extract money from other's account!";
  my $toequiz = $params->param('toequiz');
  (-e $toequiz) or die "Target file does not exist!\n";
  my ($to,$filename); $to = $toequiz; $to =~ s{$var/users/}{}; ($to,$filename) = split(/\/equizzes\//,$to);
  ($to eq $uemail) and die "You don't need to pay yourself";

  my $amount = findprice($toequiz);
  (defined($amount) and ($amount > 0)) or die "Invalid price.\n";
  my $frombalance = balance($from); my $tobalance = balance($to);
print "from is $frombalance and to is $tobalance from $from to $to $toequiz amount $amount\n\n\n\n";
  ($frombalance >= $amount) or die "You don't have enough money in your account";

  unlink("$var/users/$from/balance=$frombalance"); unlink("$var/users/$to/balance=$tobalance");
  $frombalance -= $amount; $tobalance += $amount;
  touch("$var/users/$from/balance=$frombalance"); touch("$var/users/$to/balance=$tobalance");
  touch("$var/users/$uemail/equizzes/$to\~$filename\~paid");

  transactionlog($c->tx->remote_address,$from,$to,$filename,$amount);
 
  $c->flash(message => "\$$amount paid. Current balance is \$$frombalance.")->redirect_to("/equizrender2?f=$filename&author=$to");
};

1;

