#!/usr/bin/perl

use strict;
use warnings;


use Cwd 'abs_path';
our $ROOT;
BEGIN { ($ROOT = abs_path $0) =~ s{/util/l10nusage\.pl$}{}; }

use lib $ROOT.'/lib';
use LangFile;

my $langtxt = "$ROOT/data/lang.txt";


my %used;
my %exists;
my $reqs;


sub readexists {
  my $r = LangFile->new(read => $langtxt);
  while(my $l = $r->read()) {
    $exists{$l->[1]} = 1 if $l->[0] eq 'key';
  }
}


sub readstats {
  open my $F, '<', '/tmp/vndb-I18N-stats' or die $!;
  while(<$F>) {
    chomp;
    if(/^REPORT (\d+)/) {
      $reqs += $1;
    } elsif(/^(_[^ ]+) (\d+)/) {
      $used{$1} += $2;
    }
  }
}


sub printstats {
  print "Used translation strings\n";
  printf "%30s %6d %6.3f\n", $_, $used{$_}, $used{$_}/$reqs
    for(sort { $used{$b} <=> $used{$a} } keys %used);
  print "\n";
  print "Unused translation strings:\n";
  printf "  %s\n", $_ for(sort grep !$used{$_}, keys %exists);
  print "\n";
  printf "Unique strings: %d, unused: %d\n", scalar keys %used, keys(%exists) - keys(%used);
}

readexists;
readstats;
printstats;

