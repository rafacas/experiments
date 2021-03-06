#!/usr/bin/env perl

use strict;
use warnings;
use Log::Message::Simple qw[msg error debug
 carp croak cluck confess];
use Log::Message::Simple qw[:STD :CARP];
use JSON::PP; # JSON::PP has been a core module since perl 5.14

# Logging options
my $verbose = 1;
my $debug = 1;

my $check_interval = 60; # Send data every minute

# Network traffic values 
my $network_traffic_last_check = {};

# perl version check 
debug("perl version: $^V", $debug);
my $version = $^V;
$version =~ /v([0-9]+)\.([0-9]+)\.([0-9]+)/;
my ($M_v, $m_v) = ($1, $2);
# Script only run between versions 5.14.x - 5.18.x
# If version < 5.14.x -> JSON::PP is not included in perl core
# If version > 5.18.x -> Log::Message::Simple has been removed from core
croak("perl5 is needed") if ($M_v != 5); # Is this really necessary?
croak("unsupported perl version (must be between 5.14.x and 5.18.x)") if ($m_v < 14 || $m_v > 18); 

# flush the buffer
$| = 1;

# daemonize the agent
#&daemonize;

while(1){
    my $wake_time = time + $check_interval;
    my $stats = do_checks();
    send_stats($stats);
    sleep($wake_time - time);
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
        debug("get_loadavg: 1:$loadavg->{1} 5:$loadavg->{5} 15:$loadavg->{15}", $debug);
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
        $mem = { 'MemTotal'  => $meminfo->{MemTotal},
                 'MemFree'   => $meminfo->{MemFree},
                 'Buffers'   => $meminfo->{Buffers},
                 'Cached'    => $meminfo->{Cached},
                 'SwapTotal' => $meminfo->{SwapTotal},
                 'SwapFree'  => $meminfo->{SwapFree} };
        debug("get_memory: MemTotal:$mem->{MemTotal} MemFree:$mem->{MemFree} Buffers:$mem->{Buffers} Cached:$mem->{Cached} SwapTotal:$mem->{SwapTotal} SwapFree: $mem->{SwapFree}", $debug);
    } else {
        debug("get_memory: unsupported platform: $^O", $debug);
    }

    debug("get_memory: completed", $debug);
    return $mem;
}

# Get network stats parsing /proc/dev/net
sub get_network_traffic {
    debug("get_network_traffic: start", $debug);
    my $network_traffic;
    if ($^O eq 'linux'){
        debug("get_network_traffic: linux", $debug);
        my $network_stats = {};
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

        debug("get_network_traffic: get network traffic since last check", $debug);
        $network_traffic = {};
        foreach my $iface (keys %$network_stats){
            if($network_traffic_last_check->{$iface}){
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
    
    } else {
        debug("get_network_traffic: unsupported platform: $^O", $debug);
        return $network_traffic;
    }

    debug("get_network_traffic: completed", $debug);
    return $network_traffic;
}

sub get_cpu_stats {
    debug("get_cpu_stats: start", $debug);
    my $cpu;
    if ($^O eq 'linux'){
        debug("get_cpu_stats: linux", $debug);
        $cpu = {};
        debug("get_cpu_stats: mpstat -P ALL", $debug);
        open MPSTAT, "mpstat -P ALL |"; # or die
        my @cpu_stat_fields = qw(usr nice sys iowait irq soft steal guest idle);
        # number of fields of the mpstat time depend on the system: 
        # 12 hour time - 2 fields: 01:18:34 PM
        # 24 hour time - 1 field: 13:18:34
        my @hour_12 = qw(time am_pm);
        my @hour_24 = qw(time);
        my @timestamp_fields = @hour_24;
        debug("get_cpu_stats: parsing", $debug);
        while (<MPSTAT>){
            chomp $_;
            next if $_ !~ /^[0-9]/ || $_ =~ /CPU/; # skip the first two lines and the header
            debug("get_cpu_stats: $_", $debug);
            @timestamp_fields = @hour_12 if $_ =~ /(AM|PM)/;
            my (%timestamp, $cpu_id, %cpu_stats);
            (@timestamp{@timestamp_fields}, $cpu_id, @cpu_stats{@cpu_stat_fields}) = split /[ ]+/, $_;
            $cpu->{$cpu_id}->{$_} = $cpu_stats{$_} for keys %cpu_stats;
        }
        close MPSTAT;
    } else {
        debug("get_cpu_stats: unsupported platform: $^O", $debug);
        return $cpu;
    }
    
    debug("get_cpu_stats: completed", $debug);
    return $cpu;
}

sub get_disk_usage {
    debug("get_disk_usage: start", $debug);
    my $disks;
    if ($^O eq 'linux'){
        debug("get_disk_usage: linux", $debug);
        $disks = {};
        my @df_fields = qw(filesystem 1k-blocks used available usage_p);
        # Run df with the -k option to get 1K (1024) byte blocks
        debug("get_disk_usage: df -k", $debug);
        open DF, "df -k |"; # or die
        while (<DF>){
            next if $. == 1; # skip the header
            chomp $_;
            debug("get_disk_usage: $_", $debug);
            my (%filesystems, $mount_point);
            (@filesystems{@df_fields}, $mount_point) = split /[ ]+/, $_;
            $disks->{$mount_point}->{$_} = $filesystems{$_} for keys %filesystems;
        }        
        close DF;
    } else {
        debug("get_disk_usage: unsupported platform: $^O", $debug);
        return $disks;
    }

    debug("get_disk_usage: completed", $debug);
    return $disks;
}

sub get_io_stats {
    debug("get_io_stats: start", $debug);
    my $io;
    if ($^O eq 'linux'){
        debug("get_io_stats: linux", $debug);
        $io = {};
        my @iostat_fields = qw(rrqm_s wrqm_s r_s w_s rkB_s wkB_s avgrq-sz avgqu-sz await r_await w_await svctm util_p);
        # Run: iostat -d -x -k 1 2
        # -d: displays the device utilisation report
        # -x: displays extended statistics
        # -k: displays statistics in kilobytes per second
        # the count is 2 because we store the second report (the first one has "noise").
        debug("get_io_stats: iostat -d -x -k 1 2", $debug);
        open IOSTAT, "iostat -d -x -k 1 2 |"; # or die
        my $first_device = 1;
        while (<IOSTAT>){
            next if $_ !~ /^Device:/;
            if ($first_device){
                $first_device = 0;
                next;
            }
            my $stats = <IOSTAT>; # discard the header ang get the stats line
            chomp $stats;
            debug("get_io_stats: $stats", $debug);
            my ($device, %io_stats);
            ($device, @io_stats{@iostat_fields}) = split /[ ]+/, $stats;
            $io->{$device}->{$_} = $io_stats{$_} for keys %io_stats;
        }
    } else {
        debug("get_io_stats: unsupported platform: $^O", $debug);
        return $io;
    }

    debug("get_io_stats: completed", $debug);
    return $io;
}

sub do_checks {
    # Check CPU load average
    my $loadavg = get_loadavg();

    # Check memory & swap
    my $memory = get_memory();

    # Check network traffic
    my $network_traffic = get_network_traffic();

    # Check CPU stats
    my $cpu_stats = get_cpu_stats();

    # Check disk usage
    my $disk_usage = get_disk_usage();

    # Check IO stats
    my $io_stats = get_io_stats();

    # Convert data to JSON
    my $stats = {};
    $stats->{loadavg} = $loadavg if defined $loadavg;
    $stats->{memory} = $memory if defined $memory;
    $stats->{network_traffic} = $network_traffic if defined $network_traffic;
    $stats->{cpu} = $cpu_stats if defined $cpu_stats;
    $stats->{disk} = $disk_usage if defined $disk_usage;
    $stats->{io} = $io_stats if defined $io_stats;

    return $stats;
}

sub send_stats {
    my $stats = shift;
    my $json_stats = encode_json $stats;
    debug("json: $json_stats", $debug);

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
