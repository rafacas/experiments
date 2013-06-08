#!/usr/bin/env perl

use strict;
use warnings;
use Log::Message::Simple;
use JSON::PP; # JSON::PP has been a core module since perl 5.14

# Logging options
my $verbose = 1;
my $debug = 1;

# Network traffic values 
my $network_traffic_last_check = {};

# perl version check: if ($] < 5.008 )


# flush the buffer
$| = 1;

# daemonize the agent
#&daemonize;

while(1){
    # Check CPU load average
    my $loadavg = get_loadavg();

    # Check memory & swap
    my $memory = get_memory();

    # Check network traffic
    my $network_traffic = get_network_traffic();

    # Check CPU stats
    my $cpu_stats = get_cpu_stats();

    # Check disk usage


    # Check IO stats


    # Send data in JSON
    my $stats = {};
    $stats->{loadavg} = $loadavg if defined $loadavg;
    $stats->{memory} = $memory if defined $memory;
    $stats->{network_traffic} = $network_traffic if defined $network_traffic;
    $stats->{cpu} = $cpu_stats if defined $cpu_stats;

    my $json_stats = encode_json $stats;
    debug("json: $json_stats", $debug);

    sleep(5);
}

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
        debug("get_loadavg: loadavg - $la", $debug);
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
        open MEMINFO, '<', '/proc/meminfo'; # or die
        # Create a hash with the values of /proc/meminfo
        debug("get_memory: parsing", $debug);
        my $meminfo = {};
        while (<MEMINFO>){
            chomp $_;
            my @mem_values = split(/:/, $_);
            # Remove spaces and kB
            $mem_values[1] =~ /\s+([0-9]+)\s+kB/;
            $meminfo->{$mem_values[0]} = $1;
        }
        close MEMINFO;
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
sub get_network_traffic {
    debug("get_network_traffic: start", $debug);
    my $network_stats = {};
    if ($^O eq 'linux'){
        debug("get_network_traffic: linux", $debug);
        debug("get_network_traffic: opening /proc/net/dev", $debug);
        open NET_DEV, '<', '/proc/net/dev'; # or die
        my @rx_fields = qw(bytes packets errs drop fifo frame compressed multicast);
        my @tx_fields = qw(bytes packets errs drop fifo frame compressed);
        debug("get_network_traffic: parsing", $debug);
        while (<NET_DEV>){
            next if $_ !~ /:/;
            $_ =~ s/^\s+|\s+$//g;
            my ($iface, %rx, %tx);
            debug("get_network_traffic: iface - $_", $debug);
            ($iface, @rx{@rx_fields}, @tx{@tx_fields}) = split /[: ]+/, $_;
            $network_stats->{$iface}->{rx}->{$_} = $rx{$_} for keys %rx;
            $network_stats->{$iface}->{tx}->{$_} = $tx{$_} for keys %tx;
        }
        close NET_DEV;
    } else {
        debug("get_network_traffic: unsupported platform: $^O", $debug);
    }

    debug("get_network_traffic: get network traffic since last check", $debug);
    my $network_traffic = {};
    foreach my $iface (keys %$network_stats){
        if(%$network_traffic_last_check->{$iface}){
            # network traffic since last check
            my $rx = $network_stats->{$iface}->{rx}->{bytes} - $network_traffic_last_check->{$iface}->{rx};
            my $tx = $network_stats->{$iface}->{tx}->{bytes} - $network_traffic_last_check->{$iface}->{tx};
            $rx = $network_stats->{$iface}->{rx}->{bytes} if $rx < 0;
            $tx = $network_stats->{$iface}->{tx}->{bytes} if $tx < 0;
            $network_traffic->{$iface}->{rx} = $rx;
            $network_traffic->{$iface}->{tx} = $tx;
            debug("get_network_traffic: $iface - rx: $rx tx: $tx", $debug);
        } 
        # store traffic for next check
        $network_traffic_last_check->{$iface}->{rx} = $network_stats->{$iface}->{rx}->{bytes};
        $network_traffic_last_check->{$iface}->{tx} = $network_stats->{$iface}->{tx}->{bytes};
    }

    debug("get_network_traffic: completed", $debug);
    return $network_traffic;
}

sub get_cpu_stats {
    debug("get_cpu_stats: start", $debug);
    my $cpu = {};
    debug("get_cpu_stats: run mpstat -P ALL", $debug);
    open MPSTAT, "mpstat -P ALL |"; # or die
    my @cpu_stat_fields = qw(cpu usr nice sys iowait irq soft steal guest idle);
    debug("get_cpu_stats: parsing", $debug);
    while (<MPSTAT>){
        chomp $_;
        next if $_ !~ /^[0-9]/; # skip the first two lines
        next if $_ =~ /CPU/; # skip the heade # skip the header
        debug("get_cpu_stats: $_", $debug);
        my ($timestamp, %cpu_stats);
        ($timestamp, @cpu_stats{@cpu_stat_fields}) = split /[ ]+/, $_;
        $cpu->{$_} = $cpu_stats{$_} for keys %cpu_stats;
    }
    close MPSTAT;

    debug("get_cpu_stats: completed");
    return $cpu;
}

sub send_data {

}

# http://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux
sub daemonize {
    use POSIX;
    POSIX::setsid or die "setsid: $!";
    my $pid = fork ();
    if ($pid < 0) {
        die "fork: $!";
    } elsif ($pid) {
        exit 0;
    }
    chdir "/";
    umask 0;
    foreach (0 .. (POSIX::sysconf (&POSIX::_SC_OPEN_MAX) || 1024)){
        POSIX::close $_;
    }
    open (STDIN, "</dev/null");
    open (STDOUT, ">/dev/null");
    open (STDERR, ">&STDOUT");
}
