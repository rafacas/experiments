#!/usr/bin/env perl

use strict;
use warnings;
use Log::Message::Simple;
use JSON::PP; # JSON::PP has been a core module since perl 5.14

# Logging options
my $verbose = 1;
my $debug = 1;

# perl version check: if ($] < 5.008 )

# Check CPU Load Average
my $loadavg = getLoadAvg();

# Check Memory & Swap
my $mem = getMemory();

# Network traffic
getNetwork();

# CPU stats: mpstat


# Disk usage: df


# IO stats: iostat


# Send data in JSON
my $stats = {};
$stats->{loadavg} = $loadavg if defined $loadavg;
$stats->{mem} = $mem if defined $mem;

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
        debug("getLoadAvg: unsupported platform ($^O)", $debug);
    }

    debug("getLoadAvg: completed", $debug);
    return $loadavg;
}

sub getMemory {
    my $mem;
    if ($^O eq 'linux'){
        debug("getMemory: start", $debug);
        debug("getMemory: opening /proc/meminfo", $debug);
        open MEM, '<', '/proc/meminfo'; # or die
        # Create a hash with the values of /proc/meminfo
        debug("getMemory: parsing", $debug);
        my $meminfo = {};
        while (<MEM>){
            chomp $_;
            my @mem_values = split(/:/, $_);
            # Remove spaces and kB
            $mem_values[1] =~ /\s+([0-9]+)\s+kB/;
            $meminfo->{$mem_values[0]} = $1;
        }
        close MEM;
        debug("getMemory: mem hash", $debug);
        $mem = { 'MemTotal'  => $meminfo->{MemTotal},
                 'MemFree'   => $meminfo->{MemFree},
                 'Buffers'   => $meminfo->{Buffers},
                 'Cached'    => $meminfo->{Cached},
                 'SwapTotal' => $meminfo->{SwapTotal},
                 'SwapFree'  => $meminfo->{SwapFree} };
    } else {
        debug("getMemory: unsupported platform: $^O", $debug);
    }

    debug("getMemory: completed", $debug);
    return $mem;
}

sub getNetwork {
    if ($^O eq 'linux'){
        open NET, '<', '/proc/net/dev'; # or die
        #print <$net>;
        close NET;
    } else {
        print "Unsupported platform: $^O\n";
    }
}

sub send_data {

}
