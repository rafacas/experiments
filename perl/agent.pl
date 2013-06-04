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
my $loadavg = get_loadavg();

# Check Memory & Swap
my $mem = get_memory();

# Network traffic
my $net = get_network();

# CPU stats: mpstat


# Disk usage: df


# IO stats: iostat


# Send data in JSON
my $stats = {};
$stats->{loadavg} = $loadavg if defined $loadavg;
$stats->{mem} = $mem if defined $mem;
$stats->{net} = $net if defined $net;

my $json_stats = encode_json $stats;
debug("json: $json_stats", $debug);

# SUBROUTINES

# Get load average stats parsing /proc/loadavg
sub get_loadavg {
    debug("get_loadavg: start", $debug);
    my $loadavg;
    if ($^O eq 'linux'){
        debug("get_loadavg: linux", $debug);
        debug("get_loadavg: opening /proc/loadavg file", $debug);
        open LOADAVG, '<', '/proc/loadavg'; # or die
        my $la = <LOADAVG>;
        chomp $la;
        debug("get_loadavg: loadavg -> $la", $debug);
        close LOADAVG;
        debug("get_loadavg: parsing", $debug);
        my @loadavgs = split(/ /, $la);
        $loadavg = {'1'=>$loadavgs[0], '5'=>$loadavgs[1], '15'=>$loadavgs[2]};
    } else {
        debug("get_loadavg: unsupported platform ($^O)", $debug);
    }

    debug("get_loadavg: completed", $debug);
    return $loadavg;
}

# Get memory stats parsing /proc/meminfo
sub get_memory {
    debug("get_memory: start", $debug);
    my $mem;
    if ($^O eq 'linux'){
        debug("get_memory: linux", $debug);
        debug("get_memory: opening /proc/meminfo", $debug);
        open MEM, '<', '/proc/meminfo'; # or die
        # Create a hash with the values of /proc/meminfo
        debug("get_memory: parsing", $debug);
        my $meminfo = {};
        while (<MEM>){
            chomp $_;
            my @mem_values = split(/:/, $_);
            # Remove spaces and kB
            $mem_values[1] =~ /\s+([0-9]+)\s+kB/;
            $meminfo->{$mem_values[0]} = $1;
        }
        close MEM;
        debug("get_memory: mem hash", $debug);
        $mem = { 'MemTotal'  => $meminfo->{MemTotal},
                 'MemFree'   => $meminfo->{MemFree},
                 'Buffers'   => $meminfo->{Buffers},
                 'Cached'    => $meminfo->{Cached},
                 'SwapTotal' => $meminfo->{SwapTotal},
                 'SwapFree'  => $meminfo->{SwapFree} };
    } else {
        debug("get_memory: unsupported platform: $^O", $debug);
    }

    debug("get_memory: completed", $debug);
    return $mem;
}

# Get network stats parsing /proc/dev/net
# https://gist.github.com/jyotty/5052108
sub get_network {
    debug("get_network: start", $debug);
    my $network;
    if ($^O eq 'linux'){
        debug("get_network: linux", $debug);
        debug("get_network: opening /proc/net/dev", $debug);
        open NET, '<', '/proc/net/dev'; # or die
        my @rx_fields = qw(bytes packets errs drop fifo frame compressed multicast);
        my @tx_fields = qw(bytes packets errs drop fifo frame compressed);
        debug("get_network: parsing", $debug);
        $network = {};
        while (<NET>){
            next if $_ !~ /:/;
            $_ =~ s/^\s+|\s+$//g;
            my ($iface, %rx, %tx);
            debug("get_network: iface -> $_", $debug);
            ($iface, @rx{@rx_fields}, @tx{@tx_fields}) = split /[: ]+/, $_;
            $network->{$iface}->{rx}->{$_} = $rx{$_} for keys %rx;
            $network->{$iface}->{tx}->{$_} = $tx{$_} for keys %tx;
        }
        close NET;
    } else {
        debug("get_network: unsupported platform: $^O", $debug);
    }

    debug("get_network: completed", $debug);
    return $network;
}

sub send_data {

}
