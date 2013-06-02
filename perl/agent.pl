#!/usr/bin/env perl

use strict;
use warnings;
use Log::Message::Simple;

# Logging options
my $verbose = 1;
my $debug = 1;

# Check CPU Load Average
getLoadAvg();

# Check Memory & swap
getMemory();

# Network traffic: /proc/net/dev
getNetwork();

# CPU stats: mpstat


# Disk usage: df


# IO stats: iostat


# Send data in JSON
# http://search.cpan.org/~makamaka/JSON-2.58/lib/JSON.pm
# JSON::PP has been a core module since perl 5.14
# perl version check: if ($] < 5.008 )

# SUBROUTINES

sub getLoadAvg {
    debug("getLoadAvg: start", $debug);
    my $loadavg;
    if ($^O eq 'linux'){
        debug("getLoadAvg: linux", $debug);
        debug("getLoadAvg: opening /proc/loadavg file", $debug);
        open LOADAVG, '<', '/proc/loadavg'; # or die
        $loadavg = <LOADAVG>;
        chomp $loadavg;
        debug("getLoadAvg: loadavg -> $loadavg", $debug);
        close LOADAVG;
    } else {
        debug("Unsupported platform: $^O", $debug);
    }

    debug("getLoadAvg: completed", $debug);

}

sub getMemory {
    if ($^O eq 'linux'){
        open MEM, '<', '/proc/meminfo';
        #print <$mem>;
        close MEM;
    } else {
        print "Unsupported platform: $^O\n";
    }
}

sub getNetwork {
    if ($^O eq 'linux'){
        open NET, '<', '/proc/net/dev';
        #print <$net>;
        close NET;
    } else {
        print "Unsupported platform: $^O\n";
    }
}
