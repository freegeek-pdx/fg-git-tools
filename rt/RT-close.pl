#!/usr/bin/perl

# TODO: have post-update run --pending on trunk and --close on the
# tags. and make sure that ./script/release gets updated correctly wrt
# order.

use strict;
use warnings;

use FindBin;

use lib $FindBin::RealBin . "/perllib/";

my ($status, $message, $action);

if(! (-f "dpkg-parsechangelog" || -f "debian/changelog") ) {
    exit;
}

open FOO, "dpkg-parsechangelog|";
my @list = <FOO>;
close FOO;

my $pkg = @{[split(/ /, $list[0])]}[1];
my $version = @{[split(/ /, $list[1])]}[1];
chomp $pkg;
chomp $version;

my $opt = $ARGV[0] || "";

my @restrict = ();

my $debug = 1;

if($opt eq "--git") {
    my $oldref = $ARGV[1];
    my $newref = $ARGV[2];
    $oldref = `git rev-parse $oldref`;
    $newref = `git rev-parse $newref`;
    chomp $oldref;
    chomp $newref;
    if(!($oldref =~ /^0*$/ || $newref =~ /^0*$/)) {
        my $diff = `git diff $oldref..$newref | filterdiff -i '*ChangeLog*' -i '*changelog*' | grep ^+`;
        @restrict = get_closes($diff);
	if(scalar(@restrict) == 0) {
            print "No bugs to check\n" if($debug);
            exit;
	}
    }
    $opt = $ARGV[3] || "";
}

if($opt eq "--pending") {
  $status = "pending";
  $action = "tagging pending";
  $message = "This bug has been fixed in the latest work in progress version of $pkg. It will soon be released, and then this ticket will be closed.";
} elsif($opt eq "--close") {
  $status = "resolved";
  $action = "closing";
  $message = "The new version ($version) of $pkg with this bug fixed has been released.";
} else {
  die("Usage: $0 --pending|--close");
}

print "In $action mode\n"  if($debug);

use Text::Wrap;

$Text::Wrap::columns = 72;

$message = wrap("", "", $message);
$message .= "\n\n";
$message .= "Here is the relevant changelog entry:\n";

use RT::Client::REST::FromConfig;

my $rt = RT::Client::REST::FromConfig->new();

my $in_entry = 0;
my @entries;
foreach(@list) {
  if(/^   \*/) {
    push @entries, $_;
    $in_entry = 1;
  } elsif(/^ \./) {
    $in_entry = 0;
  } elsif($in_entry) {
    $entries[scalar(@entries) - 1] .= $_;
  }
}

@entries = map {s/^  //; $_} @entries;

sub get_closes {
  return grep /[1-9]/, grep /\d/, split(/\D/, @{[shift =~ /\(closes:(.*)\)/sig]}[0] || 0);
}

use RT::Client::REST::Ticket;

sub intersect {
    my ($arr1, $arr2) = @_;
    my %hash;
    foreach(@$arr2) {
        $hash{$_} = 1;
    }
    return grep { $hash{$_} } @$arr1;
}

foreach my $entry(@entries) {
  my @closes = get_closes($entry);
  @closes = intersect(\@closes, \@restrict) if(scalar(@restrict) > 0);
  foreach my $bug(@closes) {
      print "Checking bug: $bug\n" if($debug);
    my $ticket = RT::Client::REST::Ticket->new(rt => $rt, id => $bug)->retrieve;
    if($ticket->status ne $status) {
      print $action . " #" . $bug . "\n";
      my $msg = $message . $entry;
      $rt->correspond(ticket_id => $ticket->id, message => $msg);
      $ticket->status($status);
      $ticket->store();
    }
  }
}

