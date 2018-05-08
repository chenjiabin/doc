#!/usr/bin/perl
#
# check_traffic v 1.0 - Nagios(r) network traffic monitor plugin
#
# Copyright (c) 2003 Adrian Wieczorek, <ads (at) irc.pila.pl>
#
# Send me bug reports, questions and comments about this plugin.
# Latest version of this software: http://adi.blink.pl/nagios
#
# Fixes by Andreas Ericsson <ae@op5.se>
#  snmpget is now called with OID's instead of MIB names, to prevent
#  from loading mibs (preserve resources)
#
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307
#
###############################################################################

# use strict;
use lib "/opt/plugins";
use utils qw (%ERRORS $TIMEOUT);
use Getopt::Long;
my $VERSION      = "0.99";

my $TRAFFIC_FILE = "/opt/monitor/var/traffic/traffic";
my $DB_PATH      = "/opt/monitor/var/traffic/db";

# RRD support:
my $WITH_RRD     = 0;
my $RRDTOOL      = "/usr/bin/rrdtool";

# Reasonably default values
my $iface_speed = 0; # autodetected if left to zero
my $COMMUNITY    = "public";
my $warn_usage = 75;
my $crit_usage = 90;
my $speed_oid = ".1.3.6.1.2.1.2.2.1.5";         # snmp v1 speed
my $highspeed_oid = ".1.3.6.1.2.1.31.1.1.1.15"; # snmp v1 high speed
my $in_oid = ".1.3.6.1.2.1.2.2.1.10";           # snmp v1 in-octets
my $out_oid = ".1.3.6.1.2.1.2.2.1.16";          # snmp v1 out-octets
my $counter_max = 4294967295;                   # snmp v1 is 32bit

my ($v3_authprot, $v3_authpass, $v3_privprot, $v3_privpass, $v3_secname, $v3_seclevel);

my ($in_usage, $out_usage, $in_traffic, $out_traffic);
my ($in_prefix, $out_prefix) = "";
my ($in_bits, $out_bits, $in_bytes,$out_bytes) = 0;

my ($db_file, $row, $update_time);
my ($iface_number, $iface_descr, $host_address, $host_port);

my $snmp_agent; #Stores host address and possibly port to snmp service, as used by snmpget

my ($last_check_time, $last_in_bytes, $last_out_bytes) = 0;
my @last_values;

my ($fstr, $raw_bps_string);
my $status = 'OK';
my @snmp_ret;
my $snmp_version = '1';
my $perfdata_bits;

my @prefix_table = ('K', 'M', 'G');
my $i = 0;
my $denom = 1000;

sub print_usage() {
	print "Usage: check_traffic -H host -i if_number [ -b if_max_speed ] [ -w warn ] [ -c crit ] [ -C community ]\n\n";
	print "Usage: check_traffic -H host -i if_number [ -b if_max_speed ] [ -w warn ] [ -c crit ] \\\n";
	print "                     [ -a authprot -A authpass-x privprot -X privpass ] [ -u user ] [ -l seclevel ]\n\n";
	print "Options:\n";
	print " -H --host STRING or IPADDRESS\n";
	print "   Check interface on the indicated host.\n";
	print " -p --port INTEGER\n";
	print "   Set the SNMP port number\n";
	print " -i --interface INTEGER\n";
	print "   Interface number assigned by SNMP agent.\n";
	print " -b --bps INTEGER\n";
	print "   Interface maximum speed in bytes per second.\n";
	print " -B --perfdatabits\n";
	print "   Output performancedata in bits.\n";
	print " -r --rrd STRING\n";
	print "   Interface description used to store values in correct RRD file.\n";
	print " -w --warning INTEGER[%b](, INTEGER[%b])\n";
	print "   % of bandwidth usage necessary to result in warning status(default)\n";
	print "   or bits amount necessary to result in warning status\n";
	print " -c --critical INTEGER[%b](, INTEGER[%b])\n";
	print "   % of bandwidth usage necessary to result in critical status(default)\n";
	print "   or bits amount necessary to result in warning status\n";
	print " -C --community STRING\n";
	print "   Community name to use when connecting.\n";
	print " -a --authprot STRING\n";
	print "   Authentication protocol for SNMPv3. (md5 or sha)\n";
	print " -P --privprot STRING\n";
	print "   Privacy protocol for SNMPv3. (des or aes)\n";
	print " -A --authpass STRING\n";
	print "   Authentication pass phrase for SNMPv3.\n";
	print " -X --privpass STRING\n";
	print "   Privacy pass phrase for SNMPv3.\n";
	print " -U --secname STRING\n";
	print "   Security name for SNMPv3.\n";
	print " -L --seclevel STRING\n";
	print "   Security level for SNMPv3. (noAuthNoPriv|authNoPriv|authPriv)\n";
	print " -v --snmpversion STRING\n";
	print "   Version to use. Supported options are '1' (default), '2c' and '3'\n";
	exit($ERRORS{"UNKNOWN"});
}

sub conv_threshold_value {
	my ($arg, $ispeed) = @_;
	my ($perc_val, $bits_val);
	my ($value, $prefix) = $arg =~ m/([0-9]*)(.*)/;

	if ((!$prefix || $prefix eq "%") && $value >= 0 && $value <= 100) {
		$perc_val = $value;
		$bits_val = $value * $ispeed / 100;
	}
	elsif ($prefix eq "b") {
		$perc_val = $value / $ispeed * 100;
		$bits_val = $value;
	}

	return ($perc_val, $bits_val);
}

if ($#ARGV == -1) {
	print_usage();
}

# get options the usual way
Getopt::Long::Configure('bundling');
GetOptions(
	"C=s" => \$COMMUNITY,      "community=s"   => \$COMMUNITY,
	"H=s" => \$host_address,   "host=s"        => \$host_address,
	"p=i" => \$host_port,      "port=i"        => \$host_port,
	"i=i" => \$iface_number,   "interface=i"   => \$iface_number,
	"c=s" => \$crit_usage,     "critical=s"    => \$crit_usage,
	"w=s" => \$warn_usage,     "warning=s"     => \$warn_usage,
	"r=s" => \$iface_descr,    "rrd=s"         => \$iface_descr,
	"b=s" => \$raw_bps_string, "bps=s"         => \$raw_bps_string,
	"v=s" => \$snmp_version,   "snmpversion=s" => \$snmp_version,
	"B"   => \$perfdata_bits,  "perfdatabits"  => \$perfdata_bits,
	"a=s" => \$v3_authprot,    "authprot=s"    => \$v3_authprot,
	"P=s" => \$v3_privprot,    "privprot=s"    => \$v3_privprot,
	"A=s" => \$v3_authpass,    "authpass=s"    => \$v3_authpass,
	"X=s" => \$v3_privpass,    "privpass=s"    => \$v3_privpass,
	"U=s" => \$v3_secname,     "secname=s"     => \$v3_secname,
	"L=s" => \$v3_seclevel,    "seclevel=s"    => \$v3_seclevel,
);

my ($crit_usage_in, $crit_usage_out) = split(',', $crit_usage);
my ($warn_usage_in, $warn_usage_out) = split(',', $warn_usage);

$crit_usage_out = $crit_usage_in if (!defined($crit_usage_out));
$warn_usage_out = $warn_usage_in if (!defined($warn_usage_out));

if($snmp_version =~ m/^2/) {
	$snmp_version = "2c";
	$in_oid = ".1.3.6.1.2.1.31.1.1.1.6";
	$out_oid = ".1.3.6.1.2.1.31.1.1.1.10";
	$counter_max = (4294967296 * 4294967296) - 1;
}
elsif($snmp_version =~ m/^3/ || $v3_authprot) { 
	$snmp_version = "3";
	$in_oid = ".1.3.6.1.2.1.31.1.1.1.6";
	$out_oid = ".1.3.6.1.2.1.31.1.1.1.10";
	$counter_max = (4294967296 * 4294967296) - 1;
}
else {
	$snmp_version = "1";
}

if($raw_bps_string) {
	$_ = $raw_bps_string;
	m/^[^\d]*([\d.]*)(.*)/;
	$iface_speed = $1;
	$fstr = $2;
	# match most common first (optimization)
	if($fstr =~ m/^[mM]/) {
		$iface_speed = $iface_speed * 1000000;
	}
	elsif($fstr =~ m/^[kK]/) {
		$iface_speed = $iface_speed * 1000;
	}
	elsif($fstr =~ m/^[gG]/) {
		$iface_speed = $iface_speed * 1000000000;
	}
	else {
		$iface_speed = $iface_speed;
	}
}

if(!$host_address || !$iface_number || ($WITH_RRD and !$iface_descr)) {
	print_usage();
}

# The port number is a part of the agent/host_address
$snmp_agent = $host_address;
if( $host_port ) {
	$snmp_agent = "$host_address:$host_port";
}

# make sure the web-user can read and write to the files
umask(002);

my $cmd = "snmpget -m: -Ovq -v $snmp_version $snmp_agent -c $COMMUNITY " .
  "$speed_oid.$iface_number " .
  "$in_oid.$iface_number " .
  "$out_oid.$iface_number";
if ($v3_authprot) {
  $cmd = "snmpget -m: -Ovq -v $snmp_version $snmp_agent " .
  (($v3_seclevel =~ /^authNoPriv/i) ? "-a $v3_authprot -A $v3_authpass " :
  (($v3_seclevel =~ /^authPriv/i) ?  "-a $v3_authprot -A $v3_authpass -x $v3_privprot -X $v3_privpass " : "")) .
  ($v3_secname ? "-u $v3_secname " : "") .
  ($v3_seclevel ? "-l $v3_seclevel " : "") .
  "$speed_oid.$iface_number " .
  "$in_oid.$iface_number " .
  "$out_oid.$iface_number";
}
# print "Running:\n $cmd\n";
$_ = `$cmd`;
# print "$_\n";
if($?) {
	printf("SNMP ERROR: No data received from host.\n");
	exit($ERRORS{'CRITICAL'});
}
if ($_ =~ m/^No Such.*/i) {
	printf("SNMP ERROR: Could not find interface #$iface_number.\n");
	exit($ERRORS{'CRITICAL'});
}
@snmp_ret = split(/\n/);
if(!$iface_speed) {
	$iface_speed = $snmp_ret[0];
	if ($iface_speed == 4294967295) {
		# looks like Gigabit interface, so read ifHighSpeed
		my $cmd = "snmpget -m: -Ovq -v $snmp_version $snmp_agent -c $COMMUNITY $highspeed_oid.$iface_number";
		if ($v3_authprot) {
		  $cmd = "snmpget -m: -Ovq -v $snmp_version $snmp_agent " .
		  (($v3_seclevel =~ /^authNoPriv/i) ? "-a $v3_authprot -A $v3_authpass " :
		  (($v3_seclevel =~ /^authPriv/i) ?  "-a $v3_authprot -A $v3_authpass -x $v3_privprot -X $v3_privpass " : "")) .
		  ($v3_secname ? "-u $v3_secname " : "") .
		  ($v3_seclevel ? "-l $v3_seclevel " : "") .
		  "$highspeed_oid.$iface_number";
		}
		$_ = `$cmd`;
		# print "$_\n";
		if($?) {
			printf("SNMP ERROR: No data received from host.\n");
			exit($ERRORS{'CRITICAL'});
		}
		$iface_speed = (chomp $_) * 1000000;
	}
}
$in_bytes = $snmp_ret[1];
$out_bytes = $snmp_ret[2];

my $warn_bits_in;
my $crit_bits_in;
my $warn_bits_out;
my $crit_bits_out;
($crit_usage_in, $crit_bits_in) = conv_threshold_value($crit_usage_in, $iface_speed);
($warn_usage_in, $warn_bits_in) = conv_threshold_value($warn_usage_in, $iface_speed);
($crit_usage_out, $crit_bits_out) = conv_threshold_value($crit_usage_out, $iface_speed);
($warn_usage_out, $warn_bits_out) = conv_threshold_value($warn_usage_out, $iface_speed);

if (!$crit_usage_in || !$warn_usage_in || !$crit_usage_out || !$warn_usage_out) {
	print_usage();
}

open(FILE, "<" . $TRAFFIC_FILE . "_if" . $iface_number . "_" . $host_address);
while(($row = <FILE>)) {
	@last_values = split(":",$row);
	$last_check_time = $last_values[0];
	$last_in_bytes = $last_values[1];
	$last_out_bytes = $last_values[2];
}
close(FILE);

# see if we have rotated the counters and act accordingly
if($last_in_bytes > $in_bytes) {
	$last_in_bytes = $last_in_bytes - $counter_max;
}
if($last_out_bytes > $out_bytes) {
	$last_out_bytes = $last_out_bytes - $counter_max;
}

$update_time = time;

$TRAFFIC_FILE = $TRAFFIC_FILE . "_if" . $iface_number . "_" . $host_address;
# print "Writing data to $TRAFFIC_FILE\n";
open(FILE, ">" . $TRAFFIC_FILE)
  or die "Can't open $TRAFFIC_FILE for writing: $!";
print FILE "$update_time:$in_bytes:$out_bytes\n";
close(FILE);

if($WITH_RRD) {
	$db_file = $host_address."_".$iface_descr.".rrd";
	`$RRDTOOL update $DB_PATH/$db_file $update_time:$in_bytes:$out_bytes`;
}

# prevent "Illegal division by zero" (should never happen in production)
if($last_check_time == time) {
	$last_check_time--;
}
$in_traffic = sprintf("%.2f", ($in_bytes - $last_in_bytes) / (time - $last_check_time));
$out_traffic = sprintf("%.2f", ($out_bytes - $last_out_bytes) / (time - $last_check_time));

$in_bits = $in_traffic * 8;
$out_bits = $out_traffic * 8;

if ($iface_speed) {
	$in_usage = sprintf("%.2f", $in_bits / $iface_speed * 100);
	$out_usage = sprintf("%.2f", $out_bits / $iface_speed * 100);
}

if(defined($perfdata_bits)) {
	if($in_bits > $crit_bits_in || $out_bits > $crit_bits_out) {
		$status = 'CRITICAL';
	}
	elsif($in_bits > $warn_bits_in || $out_bits > $warn_bits_out) {
		$status = 'WARNING';
	}
}else{
	if($in_usage > $crit_usage_in || $out_usage > $crit_usage_out) {
		$status = 'CRITICAL';
	}
	elsif($in_usage > $warn_usage_in || $out_usage > $warn_usage_out) {
		$status = 'WARNING';
	}
}

for($i = 0; $i < 3; $i++) {
	if($in_bits > 1000) {
		$in_prefix = $prefix_table[$i];
		$in_bits = $in_bits / 1000;
	}
	if($out_bits > 1000) {
		$out_prefix = $prefix_table[$i];
		$out_bits = $out_bits / 1000;
	}
}
# print "in_bits: $in_bits $in_prefix bit/s\n";
# print "out_bits: $out_bits $out_prefix bit/s\n";

# $in_bytes = sprintf("%.2f", ($in_bytes / 1024) / 1024);
# $out_bytes = sprintf("%.2f", ($out_bytes / 1024) / 1024);

# print "Total RX Bytes: $in_bytes MB, Total TX Bytes: $out_bytes MB<br>";
print "$status - Avg Traffic: ";
printf("%.2f %sbit/s (%.2f%%) in, ", $in_bits, $in_prefix, $in_usage);
printf("%.2f %sbit/s (%.2f%%) out", $out_bits, $out_prefix, $out_usage);
# perfdata
if(defined($perfdata_bits)) {
	print "|in_traffic=" . ($in_traffic * 8) . "bit/s;$warn_bits_in;$crit_bits_in;; " .
	  "out_traffic=" . ($out_traffic * 8) . "bit/s;$warn_bits_out;$crit_bits_out;;\n";
#	print "|in_traffic=$in_bits$in_prefix"."bit/s;$warn_bits_in;$crit_bits_in;; " .
#	  "out_traffic=$out_bits$out_prefix"."bit/s;$warn_bits_out;$crit_bits_out;;\n";
}else{
	print "|in_traffic=$in_usage%;$warn_usage_in;$crit_usage_in;; " .
	  "out_traffic=$out_usage%;$warn_usage_out;$crit_usage_out;;\n";
#	print "|in_traffic=$in_usage%;$warn_usage_in;$crit_usage_in;; " .
#	  "out_traffic=$out_usage%;$warn_usage_out;$crit_usage_out;;\n";
}
exit($ERRORS{$status});
