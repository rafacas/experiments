#!/usr/bin/env perl

use strict;
use warnings;


# Check CPU Load Average
my $loadavg;
if ($^O eq 'linux'){
    open LOADAVG, '<', '/proc/loadavg'; # or die
    $loadavg = <LOADAVG>;
    chomp $loadavg;
    close LOADAVG;
} else {
    print "Unsupported platform: $^O\n";
}

print "$loadavg\n";

# Check Memory & swap
if ($^O eq 'linux'){
    open MEM, '<', '/proc/meminfo';
#    print <$mem>;
    close MEM;
} else {
    print "Unsupported platform: $^O\n";
}

# Network traffic: /proc/net/dev
if ($^O eq 'linux'){
    open NET, '<', '/proc/net/dev';
#    print <$net>;
    close NET;
} else {
    print "Unsupported platform: $^O\n";
}

# CPU stats: mpstat
# Disk usage: df
# IO stats: iostat


# Send data in JSON
# http://search.cpan.org/~makamaka/JSON-2.58/lib/JSON.pm
# JSON::PP has been a core module since perl 5.14
# perl version check: if ($] < 5.008 )
