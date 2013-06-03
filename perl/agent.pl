#!/usr/bin/env perl

use strict;
use warnings;
use Log::Message::Simple;
use JSON::PP;

# Logging options
my $verbose = 1;
my $debug = 1;

# perl version check: if ($] < 5.008 )

# Check CPU Load Average
my $loadavg = getLoadAvg();

# Check Memory & Swap
getMemory();

# Network traffic
getNetwork();

# CPU stats: mpstat


# Disk usage: df


# IO stats: iostat


# Send data in JSON
my $stats = {};
$stats->{loadavg} = $loadavg if defined $loadavg;

my $json_stats = encode_json $stats;
debug("json: $json_stats", $debug);

# SUBROUTINES

sub getLoadAvg {
    debug("getLoadAvg: start", $debug);
    my $loadavg;
    if ($^O eq 'linux'){
        debug("getLoadAvg: linux", $debug);
        debug("getLoadAvg: opening /proc/loadavg file", $debug);
        open LOADAVG, '<', '/proc/loadavg'; # or die
        my $la = <LOADAVG>;
        chomp $la;
        debug("getLoadAvg: loadavg -> $la", $debug);
        close LOADAVG;
        debug("getLoadAvg: parsing", $debug);
        my @loadavgs = split(/ /, $la);
        $loadavg = {'1'=>$loadavgs[0], '5'=>$loadavgs[1], '15'=>$loadavgs[2]};
    } else {
        debug("getLoadAvg: Unsupported platform ($^O)", $debug);
    }

    debug("getLoadAvg: completed", $debug);
    return $loadavg;
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

sub send_data {
    # JSON::PP has been a core module since perl 5.14

}
