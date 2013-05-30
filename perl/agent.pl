#!/usr/bin/env perl

use strict;
use warnings;


# Check CPU Load Average
# /proc/loadavg 
if ($^O eq 'linux'){
    open my $la, '<', '/proc/loadavg';
    print <$la>;
    close $la;
} else {
    print "Unsupported platform: $^O\n";
}

# Memory & swap: /proc/meminfo
# Network traffic: /proc/net/dev
# CPU stats: mpstat
# Disk usage: df
# IO stats: iostat


# Send data in JSON
# http://search.cpan.org/~makamaka/JSON-2.58/lib/JSON.pm
# JSON::PP has been a core module since perl 5.14
# perl version check: if ($] < 5.008 )
