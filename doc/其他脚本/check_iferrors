#!/usr/bin/perl
#
# check_iferrors.pl - check network interfaces for errors and discards / sec
#
# This script uses snmpget which is much faster than Net::SNMP when we don't
# have to parse any mib-files. Net::SNMP is a terrible waste of cycles.
#

use POSIX;
# use strict;
use lib "/opt/plugins";
use utils qw($TIMEOUT %ERRORS);

my $db_path = "/opt/monitor/var/errors";

# set some defaults.
my $community = "public";
my $snmp_version = "1";
my $hide_community = 0;
my $only_errors = 0;
my ($host, $port);
my $snmp_agent; # Stores SNMP host and possibly port, as used by snmpget
my $warn = 1.5;
my $crit = 2.5;
my $if_index = 0;
my $timeout = $TIMEOUT;
my $status = $ERRORS{'OK'};
my ($v3_authprot, $v3_authpass, $v3_privprot, $v3_privpass, $v3_secname, $v3_seclevel);

my $sec;
my $buf = "";
my $db_file = "";
my @vals;
my $old_buf = "";
my @old_vals;
my $total = 0;
my $i;
my $val;

$SIG{'ALRM'} = sub {
	print "CRITICAL: Plugin timed out after $timeout seconds\n";
	exit($ERRORS{'CRITICAL'});
};

sub nexit($$) {
	local ($exit_code, $exit_stat) = @_;
	print("$exit_code - $exit_stat\n");
	exit($errors{$exit_code});
}

sub usage() {
	print "Usage: check_iferrors -H host -i if_index -w warn -c crit -C community [ -v version ]\n";
	print "\n";
	print "Options:\n";
	print "-H|--host (string or IP)\n";
	print "  set the target host\n";
	print "-p|--port (int)\n";
	print "  set the target host SNMP port\n";
	print "-i|--if_index|-k|--key (int)\n";
	print "  Interface index/key assigned by SNMP agent.\n";
	print "-w|--warn (float)\n";
	print "  errors+discards/sec to result in WARNING state (default $warn)\n";
	print "-c|--crit (float)\n";
	print "  errors+discards/sec to result in CRITICAL state (default $crit)\n";
	print "-C|--community (string)\n";
	print "  use read community string when connecting (default '$community')\n";
        print " -a --authprot STRING\n";
        print "  Authentication protocol for SNMPv3. (MD5 or SHA)\n";
        print " -P --privprot STRING\n";
        print "  Privacy protocol for SNMPv3. (DES or AES)\n";
        print " -A --authpass STRING\n";
        print "  Authentication pass phrase for SNMPv3.\n";
        print " -X --privpass STRING\n";
        print "  Privacy pass phrase for SNMPv3.\n";
        print " -U --secname STRING\n";
        print "  Security name for SNMPv3.\n";
        print " -L --seclevel STRING\n";
        print "  Security level for SNMPv3. (noAuthNoPriv|authNoPriv|authPriv)\n"; 
	print "-v|--snmpversion (string)\n";
	print "  snmp version to use. Supported options are '1' (default), '2c' and '3'\n";
	print "-t|--timeout (int)\n";
	print "  seconds before giving up and returning CRITICAL (default $timeout)\n";
	print "-hc|--hide-community (int)\n";
	print "  hides the community from the outputstring (default $hide_community)\n";
	print "--only-errors\n";
	print "  Perform threshold only on error values and skip discards\n";
	print "\n";
	print "NOTE:\n";
	print "This plugin measures interface errors AND discards / second\n";
	print "It also relies on $db_path being writable\n";
	print "\n";
	exit (3);
}

if($#ARGV < 3) {
	usage();
}

for($i = 0; $i <= $#ARGV; $i++) {
	if($ARGV[$i] =~/^-H|^--host/) {
		$host = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-p|^--port^/) {
		$port = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-i|^--if_index|^-k|^--key/) {
		$if_index = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-w|^--warn/) {
		$warn = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-c|^--crit/) {
		$crit = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-C|^--community/) {
		$community = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-a|^--authprot/) {
		$v3_authprot = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-P|^--privprot/) {
		$v3_privprot = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-A|^--authpass/) {
		$v3_authpass = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-X|^--privpass/) {
		$v3_privpass = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-U|^--secname/) {
		$v3_secname = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-L|^--seclevel/) {
		$v3_seclevel = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-v|^--snmpversion/) {
		$snmp_version = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^-t|^--timeout/) {
		$timeout = $ARGV[$i + 1];
	}
	elsif($ARGV[$i] =~/^--only-errors/) {
		$only_errors = 1;
	}
	elsif($ARGV[$i] =~/^-hc|^--hide-community/) {
		$hide_community = $ARGV[$i + 1];
	}
}

if(!$host) {
	print "No host specified (use the -H flag).\n";
	usage();
}
if(!int($timeout)) {
	print "Illegal timeout value specified. Timeout must be integer.\n";
	usage();
}

$snmp_agent = $host;
if(int($port)) {
	# Port is a part of host in snmpget agent string
	$snmp_agent = "$host:$port";
}

if(defined($v3_seclevel)){
    $snmp_version = "3";
}
if(defined($v3_authprot) && $v3_authprot !~ m/^(MD5|SHA)$/) {
    print "'$v3_authprot' is not an allowed authprotocol. Valid options: MD5 and SHA\n";
    exit($ERRORS{'UNKNOWN'});
}
if(defined($v3_seclevel) && $v3_seclevel !~ m/^(noAuthNoPriv|authNoPriv|authPriv)$/) {
    print "'$v3_seclevel' is not an allowed seclevel. Valid options: noAuthNoPriv, authNoPriv and authPriv\n";
    exit($ERRORS{'UNKNOWN'});
}
if(defined($v3_privprot) && $v3_privprot !~ m/^(DES|AES)$/) {
    print "'$v3_privprot' is not an allowed privprotocol. Valid options: DES and AES\n";
    exit($ERRORS{'UNKNOWN'});
}
if(defined($snmp_version) && $snmp_version !~ m/^(1|2c|3)$/) {
    print "'$snmp_version' is not an allowed snmp version. Valid options: '1' (default), '2c' and '3'\n";
    exit($ERRORS{'UNKNOWN'});
}

# Make sure Nagios doesn't have to slay.
alarm($timeout);

# Create files that can be backed up and overwritten by the webuser.
umask(002);

$db_file = $db_path . "/errors_If-$if_index" . "_$host";
if ($snmp_version =~ m/^3/) {
    my $params = "-l $v3_seclevel ";
    if ($v3_secname ne "") {
	$params = $params . " -u $v3_secname ";
    }
    if ($v3_seclevel eq "authNoPriv"){
	$params = $params . " -a $v3_authprot -A $v3_authpass ";
    }
    if ($v3_seclevel eq "authPriv"){
	$params = $params . " -a $v3_authprot -A $v3_authpass ";
	$params = $params . " -x $v3_privprot -X $v3_privpass";
    }
#    print "snmpget -v 3 $snmp_agent $params -m: -Ovq  .1.3.6.1.2.1.2.2.1.13.$if_index .1.3.6.1.2.1.2.2.1.14.$if_index .1.3.6.1.2.1.2.2.1.19.$if_index .1.3.6.1.2.1.2.2.1.20.$if_index 2> /dev/null";
    $buf = `snmpget -v 3 $snmp_agent $params -m: -Ovq  .1.3.6.1.2.1.2.2.1.13.$if_index .1.3.6.1.2.1.2.2.1.14.$if_index .1.3.6.1.2.1.2.2.1.19.$if_index .1.3.6.1.2.1.2.2.1.20.$if_index 2> /dev/null`;
} else {
    $buf = `snmpget -v $snmp_version -c $community $snmp_agent -m: -Ovq .1.3.6.1.2.1.2.2.1.13.$if_index .1.3.6.1.2.1.2.2.1.14.$if_index .1.3.6.1.2.1.2.2.1.19.$if_index .1.3.6.1.2.1.2.2.1.20.$if_index 2> /dev/null`;
}

# errors in SNMP transport method is CRITICAL, until we get return
# status FAILURE (UNKNOWN is to ambiguous)
if($? != 0) {
	if ($hide_community > 0) {
		print "Timeout: No response from $host (community: HIDDEN).\n";
	} else {
		print "Timeout: No response from $host (community: $community).\n";
	}
	exit($ERRORS{'CRITICAL'});
}

@vals = split("\n", $buf);
$vals[4] = time;
$buf = join("\n", @vals);

if (-f $db_file) {
	if (!(open(FILE, "<" . $db_file))) {
		nexit("UNKNOWN", "Could not open log file for reading ($!).");
	}
} else {
	open(FILE, ">" . $db_file) || nexit("UNKNOWN", "Could not open database for writing ($!).");
	print FILE $buf;
	close(FILE);
	print "OK :: database initialized.\n";
	exit $ERRORS{'OK'};
}

$i = 0;
while(defined(local $_ = <FILE>)) {
	$old_vals[$i++] = $_;
}
close(FILE);

open(FILE, ">" . $db_file) || nexit("UNKNOWN", "Could not open database for writing ($!).");
print FILE $buf;
close(FILE);

# calculate threshold matching value
$total = ($vals[1] - $old_vals[1]) + ($vals[3] - $old_vals[3]);
$total += ($vals[0] - $old_vals[0]) + ($vals[2] - $old_vals[2]) if (!$only_errors);

$sec = $vals[4] - $old_vals[4];

# division by zero fucks things up, so make sure to work around it.
if($sec < 1) {
	$sec = 1;
}

$val = $total / $sec;
if($val >= $crit) {
	print "CRITICAL - ";
	$status = $ERRORS{'CRITICAL'};
}
elsif($val >= $warn) {
	print "WARNING - ";
	$status = $ERRORS{'WARNING'};
}
else {
	print "OK - ";
}
if ($only_errors) {
    printf("Errors / sec = %.2f :: ", $val);
} else {
    printf("Errors+Discards / sec = %.2f :: ", $val);
}
printf("IN - discards: %d, errors: %d :: ",
	$vals[0] - $old_vals[0], $vals[1] - $old_vals[1]);
printf("OUT - discards: %d, errors: %d\n",
	$vals[2] - $old_vals[2], $vals[3] - $old_vals[3]);
printf("|discard_in=%d;$warn;$crit; discard_out=%d;$warn;$crit; error_in=%d;$warn;$crit; error_out=%d;$warn;$crit;\n",
	$vals[0] - $old_vals[0], $vals[2] - $old_vals[2], $vals[1] - $old_vals[1], $vals[3] - $old_vals[3]);

exit $status;
