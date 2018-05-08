#!/usr/bin/perl
use strict;
use lib "/opt/plugins/utils";
my $VERSION = '0.6.5';
my $COPYRIGHT = 'Copyright (C) 2005-2010 Jonathan Buhacoff <jonathan@buhacoff.net>';
my $LICENSE = 'http://www.gnu.org/licenses/gpl.txt';
my %status = ( 'OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2, 'UNKNOWN' => 3 );

# look for required modules
exit $status{UNKNOWN} unless load_modules(qw/Getopt::Long/);

# get options from command line
Getopt::Long::Configure("bundling");
my $verbose = 0;
my $help = "";
my $help_usage = "";
my $show_version = "";
my $host = "";
my $smtp_server = "";
my $smtp_port = "";
my $imap_server = "";
my $smtp_username = "";
my $smtp_password = "";
my $smtp_tls = "";
my $imap_port = "";
my $imap_username = "";
my $imap_password = "";
my $username = "";
my $password = "";
my $ssl = "";
my $imap_ssl = "";
my $mailto = "";
my $mailfrom = "";
my @header = ();
my $body = "";
my $warnstr = "";
my $critstr = "";
my $waitstr = "";
my $delay_warn = 95;
my $delay_crit = 300;
my $smtp_warn = 15;
my $smtp_crit = 30;
my $imap_warn = 15;
my $imap_crit = 30;
my $timeout = "";
my @alert_plugins = ();
my $imap_interval = 5;
my $imap_retries = 5;
my @plugins = ();
my @token_formats = ();
my $tokenfile = "";
my $default_crit = 30;
my $default_warn = 15;
my $default_wait = 5;
my $default_timeout = 60;
#my $libexec = "/usr/local/nagios/libexec";
my $libexec = ".";
my $ok;
$ok = Getopt::Long::GetOptions(
	"V|version"=>\$show_version,
	"v|verbose+"=>\$verbose,"h|help"=>\$help,"usage"=>\$help_usage,
	"w|warning=s"=>\$warnstr,"c|critical=s"=>\$critstr, "t|timeout=s"=>\$timeout,
	"libexec=s"=>\$libexec,
	# plugin settings
	"p|plugin=s"=>\@plugins, "T|token=s"=>\@token_formats,
	"A|alert=i"=>\@alert_plugins,
	"F|file=s"=>\$tokenfile,
	# common settings
	"H|hostname=s"=>\$host,
	"U|username=s"=>\$username,"P|password=s"=>\$password,
	# smtp settings
	"smtp-server=s"=>\$smtp_server,"smtp-port=i"=>\$smtp_port,
	"mailto=s"=>\$mailto, "mailfrom=s",\$mailfrom,
	"header=s"=>\@header, "body=s"=>\$body,
	# smtp-tls settings
	"smtptls!"=>\$smtp_tls,
	"smtp-username=s"=>\$smtp_username,"smtp-password=s"=>\$smtp_password,
	# delay settings
	"wait=s"=>\$waitstr,
	# imap settings
	"imap-server=s"=>\$imap_server,"imap-port=i"=>\$imap_port,
	"imap-username=s"=>\$imap_username,"imap-password=s"=>\$imap_password,
	"imap-check-interval=i"=>\$imap_interval,"imap-retries=i"=>\$imap_retries,
	"imapssl!"=>\$imap_ssl,
	);

if( $show_version ) {
	print "$VERSION\n";
	if( $verbose ) {
		print "Warning threshold: $delay_warn seconds\n";
		print "Critical threshold: $delay_crit seconds\n";
		print "Default wait: $default_wait seconds\n";
		print "Default timeout: $default_timeout seconds\n";
	}
	exit $status{UNKNOWN};
}

if( $help ) {
	exec "perldoc", $0 or print "Try `perldoc $0`\n";
	exit $status{UNKNOWN};
}

if( $host ) {
	$smtp_server = $host if $smtp_server eq "";
	$imap_server = $host if $imap_server eq "";
}

if( $username ) {
	$smtp_username = $username if $smtp_username eq "";
	$imap_username = $username if $imap_username eq "";
}

if( $password ) {
	$smtp_password = $password if $smtp_password eq "";
	$imap_password = $password if $imap_password eq "";
}

if( $ssl ) {
	$imap_ssl = $ssl if $imap_ssl eq "";
	$smtp_tls = $ssl if $smtp_tls eq "";
}

if( $help_usage
	||
	(
		scalar(@plugins) == 0
		&&
		(
			$smtp_server eq "" || $mailto eq "" || $mailfrom eq "" 
			|| $imap_server eq ""
		)
	)
	) {
	print "Usage 1: $0 -H host \n\t".
			"--mailto recipient\@your.net --mailfrom sender\@your.net --body 'message' \n\t".
			"--username username --password password \n\t".
			"[-w <seconds>] [-c <seconds>]\n\t" .
			"[--imap-check-interval <seconds> ] [--imap-retries <times> ]\n";
	print "Usage 2: $0 \n\t".
			"-p 'first plugin command with %TOKEN1% embedded' \n\t".
			"-p 'second plugin command with %TOKEN1% embedded' \n\t".
			"[-w <seconds1>,<seconds2>] [-c <seconds1>,<seconds2>] \n";
	exit $status{UNKNOWN};
}

# determine thresholds
my @warning_times = split(",", $warnstr);
my @critical_times = split(",", $critstr);
my @alarm_times = split(",", $timeout);
my @wait_times = split(",", $waitstr);
my ($dw,$sw,$rw) = split(",", $warnstr);
my ($dc,$sc,$rc) = split(",", $critstr);
my ($wait) = split(",", $waitstr);
$delay_warn = $dw if defined $dw and $dw ne "";
$smtp_warn = $sw if defined $sw and $sw ne "";
$imap_warn = $rw if defined $rw and $rw ne "";
$delay_crit = $dc if defined $dc and $dc ne "";
$smtp_crit = $sc if defined $sc and $sc ne "";
$imap_crit = $rc if defined $rc and $rc ne "";
my $smtp_thresholds = "";
$smtp_thresholds .= "-w $smtp_warn " if defined $smtp_warn and $smtp_warn ne "";
$smtp_thresholds .= "-c $smtp_crit " if defined $smtp_crit and $smtp_crit ne "";
my $imap_thresholds = "";
$imap_thresholds .= "-w $imap_warn " if defined $imap_warn and $imap_warn ne "";
$imap_thresholds .= "-c $imap_crit " if defined $imap_crit and $imap_crit ne "";
$imap_thresholds .= "--imap-check-interval $imap_interval " if defined $imap_interval and $imap_interval ne "";
$imap_thresholds .= "--imap-retries $imap_retries " if defined $imap_retries and $imap_retries ne "";
if( scalar(@alarm_times) == 1 ) {
	$default_timeout = shift(@alarm_times);
}

# determine which other options to include
my $smtp_options = "";
$smtp_options .= "-H $smtp_server " if defined $smtp_server and $smtp_server ne "";
$smtp_options .= "-p $smtp_port " if defined $smtp_port and $smtp_port ne "";
$smtp_options .= "--tls " if defined $smtp_tls and $smtp_tls;
$smtp_options .= "-U $username " if defined $smtp_username and $smtp_username ne "";
$smtp_options .= "-P $password " if defined $smtp_password and $smtp_password ne "";
$smtp_options .= "--mailto $mailto " if defined $mailto and $mailto ne "";
$smtp_options .= "--mailfrom $mailfrom " if defined $mailfrom and $mailfrom ne "";
foreach my $h( @header ) {
	$smtp_options .= "--header '$h' ";
}
my $imap_options = "";
$imap_options .= "-H $imap_server " if defined $imap_server and $imap_server ne "";
$imap_options .= "-p $imap_port " if defined $imap_port and $imap_port ne "";
$imap_options .= "-U $username " if defined $imap_username and $imap_username ne "";
$imap_options .= "-P $password " if defined $imap_password and $imap_password ne "";
$imap_options .= "--ssl " if defined $imap_ssl and $imap_ssl;

# create the report object
my $report = new PluginReport;
my @report_plugins = (); # populated later with either (smtp,imap) or (plugin1,plugin2,...)
my $time_start; # initialized later with time the work actually starts

# create token formats for use with the plugins
my @alpha = qw/a b c d e f g h i j k l m n o p q r s t u v w x y z/;
my @numeric = qw/0 1 2 3 4 5 6 7 8 9/;
my @hex = qw/0 1 2 3 4 5 6 7 8 9 a b c d e f/;
my @pgp_even = qw/aardvark absurd accrue acme adrift adult afflict ahead aimless Algol allow alone ammo ancient apple artist assume Athens atlas Aztec baboon backfield backward banjo beaming bedlamp beehive beeswax befriend Belfast berserk billiard bison blackjack blockade blowtorch bluebird bombast bookshelf brackish breadline breakup brickyard briefcase Burbank button buzzard cement chairlift chatter checkup chisel choking chopper Christmas clamshell classic classroom cleanup clockwork cobra commence concert cowbell crackdown cranky crowfoot crucial crumpled crusade cubic dashboard deadbolt deckhand dogsled dragnet drainage dreadful drifter dropper drumbeat drunken Dupont dwelling eating edict egghead eightball endorse endow enlist erase escape exceed eyeglass eyetooth facial fallout flagpole flatfoot flytrap fracture framework freedom frighten gazelle Geiger glitter glucose goggles goldfish gremlin guidance hamlet highchair hockey indoors indulge inverse involve island jawbone keyboard kickoff kiwi klaxon locale lockup merit minnow miser Mohawk mural music necklace Neptune newborn nightbird Oakland obtuse offload optic orca payday peachy pheasant physique playhouse Pluto preclude prefer preshrunk printer prowler pupil puppy python quadrant quiver quota ragtime ratchet rebirth reform regain reindeer rematch repay retouch revenge reward rhythm ribcage ringbolt robust rocker ruffled sailboat sawdust scallion scenic scorecard Scotland seabird select sentence shadow shamrock showgirl skullcap skydive slingshot slowdown snapline snapshot snowcap snowslide solo southward soybean spaniel spearhead spellbind spheroid spigot spindle spyglass stagehand stagnate stairway standard stapler steamship sterling stockman stopwatch stormy sugar surmount suspense sweatband swelter tactics talon tapeworm tempest tiger tissue tonic topmost tracker transit trauma treadmill Trojan trouble tumor tunnel tycoon uncut unearth unwind uproot upset upshot vapor village virus Vulcan waffle wallet watchword wayside willow woodlark Zulu/;
my @pgp_odd = qw/adroitness adviser aftermath aggregate alkali almighty amulet amusement antenna applicant Apollo armistice article asteroid Atlantic atmosphere autopsy Babylon backwater barbecue belowground bifocals bodyguard bookseller borderline bottomless Bradbury bravado Brazilian breakaway Burlington businessman butterfat Camelot candidate cannonball Capricorn caravan caretaker celebrate cellulose certify chambermaid Cherokee Chicago clergyman coherence combustion commando company component concurrent confidence conformist congregate consensus consulting corporate corrosion councilman crossover crucifix cumbersome customer Dakota decadence December decimal designing detector detergent determine dictator dinosaur direction disable disbelief disruptive distortion document embezzle enchanting enrollment enterprise equation equipment escapade Eskimo everyday examine existence exodus fascinate filament finicky forever fortitude frequency gadgetry Galveston getaway glossary gossamer graduate gravity guitarist hamburger Hamilton handiwork hazardous headwaters hemisphere hesitate hideaway holiness hurricane hydraulic impartial impetus inception indigo inertia infancy inferno informant insincere insurgent integrate intention inventive Istanbul Jamaica Jupiter leprosy letterhead liberty maritime matchmaker maverick Medusa megaton microscope microwave midsummer millionaire miracle misnomer molasses molecule Montana monument mosquito narrative nebula newsletter Norwegian October Ohio onlooker opulent Orlando outfielder Pacific pandemic Pandora paperweight paragon paragraph paramount passenger pedigree Pegasus penetrate perceptive performance pharmacy phonetic photograph pioneer pocketful politeness positive potato processor provincial proximate puberty publisher pyramid quantity racketeer rebellion recipe recover repellent replica reproduce resistor responsive retraction retrieval retrospect revenue revival revolver sandalwood sardonic Saturday savagery scavenger sensation sociable souvenir specialist speculate stethoscope stupendous supportive surrender suspicious sympathy tambourine telephone therapist tobacco tolerance tomorrow torpedo tradition travesty trombonist truncated typewriter ultimate undaunted underfoot unicorn unify universe unravel upcoming vacancy vagabond vertigo Virginia visitor vocalist voyager warranty Waterloo whimsical Wichita Wilmington Wyoming yesteryear Yucatan/;
my %formats = (
	'a' => sub { pick_random(@alpha) },
	'n' => sub { pick_random(@numeric) },
	'c' => sub { pick_random(@alpha,@numeric) },
	'h' => sub { pick_random(@hex) },
	'U' => sub { time },
	'X' => sub { pick_random(@pgp_even) },
	'Y' => sub { pick_random(@pgp_odd) },	
);
if( scalar(@plugins) ) {
	# scan the plugin commands for use of tokens to count how many we need
	my $token_count = 0;
	foreach my $p (@plugins) {
		my @matches = sort ($p =~ m/%TOKEN(\d+)%/g);
		my $max = pop @matches;
		$token_count = $max if defined($max) && $max > $token_count;
	}
	# create the tokens
	my @tokens = ();
	foreach my $t (1..$token_count) {
		my $format = shift @token_formats;
		$format = "U-X-Y" unless $format;
		my @format_characters = split(//, $format);
		my $token = "";
		foreach my $c (@format_characters) {
			if( defined $formats{$c} ) {
				$token .= &{$formats{$c}};
			}
			else {
				$token .= $c;
			}			
		}
		push @tokens, $token;
	}
	# substitute the tokens into each plugin command
	foreach my $p (@plugins) {
		foreach my $t (1..$token_count) {
			my $token = $tokens[$t-1];
			$p =~ s/%TOKEN$t%/$token/g;
		}
	}
	# mark plugins that are allowed to generate alerts. default behavior is to alert for all plugins.
	my %alert_plugins = ();
	if( scalar(@alert_plugins) > 0 ) {
		%alert_plugins = map { $_ => 1 } @alert_plugins;
	}
	else {
		%alert_plugins = map { $_ => 1 } (1..scalar(@plugins));
	}
	# run each plugin and store its output in a report
	$time_start = time;
	my $i = 0;
	foreach my $p( @plugins ) {
		$i++;
		my $plugin_timeout = shift(@alarm_times) || $default_timeout;
		# run the plugin
		eval {
			local $SIG{ALRM} = sub { die "exceeded timeout $plugin_timeout seconds\n" }; # NB: \n required, see `perldoc -f alarm`
			alarm $plugin_timeout;
			my $output = `$p`;
			chomp $output;
			if( $output !~ m/OK|WARNING|CRITICAL/ ) {
				print "EMAIL DELIVERY UNKNOWN - plugin $i error: $output\n";
				print "Plugin $i: $p\n" if $verbose;
				# record tokens in a file if option is enabled
				record_tokens($tokenfile,\@tokens,$time_start,undef,'UNKNOWN',$i,$output) if $tokenfile;
				exit $status{UNKNOWN};
			}
			if( $output =~ m/CRITICAL/ && $alert_plugins{$i} ) {
				print "EMAIL DELIVERY CRITICAL - plugin $i failed: $output\n";
				print "Plugin $i: $p" if $verbose;
				# record tokens in a file if option is enabled
				record_tokens($tokenfile,\@tokens,$time_start,undef,'CRITICAL',$i,$output) if $tokenfile;
				exit $status{CRITICAL};
			}
			if( $output =~ m/WARNING/ && $alert_plugins{$i} ) {
				print "EMAIL DELIVERY WARNING - plugin $i warning: $output\n";
				print "Plugin $i: $p\n" if $verbose;
				# record tokens in a file if option is enabled
				record_tokens($tokenfile,\@tokens,$time_start,undef,'WARNING',$i,$output) if $tokenfile;
				exit $status{WARNING};
			}
			$report->{"plugin".$i} = $output;
			alarm 0;
		};
		if( $@ && $alert_plugins{$i} ) {
			print "EMAIL DELIVERY CRITICAL - Could not run plugin $i: $@\n";
			print "Plugin $i: $p\n" if $verbose;
			exit $status{CRITICAL};	
		}
		# if this wasn't the last plugin, wait before continuing
		if( $i < scalar(@plugins) ) {
			my $wait = shift(@wait_times) || $default_wait;
			sleep $wait;			
		}
		# compatibility with the "not using plugins" method... pretend to calculate the total round trip time (the delay) using data from the plugins ... 
		$report->{max} = 0;
		$report->{delay} = 0;		
	}
	# register the list of reports
	foreach my $r ( 1..scalar(@plugins)) {
		push @report_plugins, "plugin".$r;		
	} 
	# record tokens in a file if option is enabled
	my $tmp_long_report = join(", ", map { "$_: $report->{$_}" } @report_plugins ) if $tokenfile;
	record_tokens($tokenfile,\@tokens,$time_start,time,'OK',scalar(@plugins),$tmp_long_report) if $tokenfile;
}
else {
	# not using plugins.
	$time_start = time;
	
	# send email via SMTP	
	my $id = $time_start; # XXX should include localhost name maybe or some random number in case the same mailbox is used for multiple delivery tests
	
	my $smtp_plugin = "$libexec/check_smtp_send";
	$smtp_plugin = "$libexec/check_smtp_send.pl" unless -e $smtp_plugin;
	unless (-e $smtp_plugin) {
		print "EMAIL DELIVERY UNKNOWN - can not locate smtp plugin: $smtp_plugin\n";
		exit $status{UNKNOWN};
	}
	my $smtp_timeout = shift(@alarm_times) || $default_timeout;
	eval {
		local $SIG{ALRM} = sub { die "exceeded timeout $smtp_timeout seconds\n" }; # NB: \n required, see `perldoc -f alarm`
		alarm $smtp_timeout;
		my $smtp = `$smtp_plugin $smtp_options --header 'Subject: Nagios Message SMTP $smtp_server ID $id.' --body 'Nagios Email Delivery Plugin\n$body' $smtp_thresholds`;
		if( $smtp !~ m/OK|WARNING|CRITICAL/ ) {
			print "EMAIL DELIVERY UNKNOWN - smtp unknown: $smtp\n";
			exit $status{UNKNOWN};
		}
		if( $smtp =~ m/CRITICAL/ ) {
			print "EMAIL DELIVERY CRITICAL - smtp failed: $smtp\n";
			exit $status{CRITICAL};
		}
		chomp $smtp;
		$report->{smtp} = $smtp;
		alarm 0;
	};
	if( $@ ) {
		print "EMAIL DELIVERY CRITICAL - Could not connect to SMTP server $smtp_server: $@\n";
		exit $status{CRITICAL};	
	}
	
	# wait before checking the delivery
	$wait = shift(@wait_times) || $default_wait;
	sleep $wait;
	
	# check email via IMAP
	my $imap_plugin = "$libexec/check_imap_receive";
	$imap_plugin = "$libexec/check_imap_receive.pl" unless -e $imap_plugin;
	unless (-e $imap_plugin) {
		print "EMAIL DELIVERY UNKNOWN - can not locate imap plugin: $imap_plugin\n";
		exit $status{UNKNOWN};
	}
	my $imap_timeout = shift(@alarm_times) || $default_timeout;
	eval {
		local $SIG{ALRM} = sub { die "exceeded timeout $imap_timeout seconds\n" }; # NB: \n required, see `perldoc -f alarm`
		alarm $imap_timeout;
		my $imap = `$imap_plugin $imap_options -s SUBJECT -s 'Nagios Message SMTP $smtp_server ID' --capture-max 'Nagios Message SMTP $smtp_server ID (\\d+)' --nodelete-captured $imap_thresholds`;
		if( $imap !~ m/OK|WARNING|CRITICAL/ ) {
			print "EMAIL DELIVERY UNKNOWN - imap unknown: $imap\n";
			exit $status{UNKNOWN};
		}
		if( $imap =~ m/CRITICAL/ ) {
			print "EMAIL DELIVERY CRITICAL - imap failed: $imap\n";
			exit $status{CRITICAL};
		}
		if( $imap =~ m/ (\d+) max/ ) {
			my $last_received = $1;
			$report->{max} = $1;
			my $delay = time - $last_received;
			$report->{delay} = $delay;
		}
		chomp $imap;
		$report->{imap} = $imap;
		alarm 0;
	};
	if( $@ ) {
		print "EMAIL DELIVERY CRITICAL - Could not connect to IMAP server $imap_server: $@\n";
		exit $status{CRITICAL};
	}
	# register the list of reports
	push @report_plugins, ("smtp","imap");
}


# calculate elapsed time and issue warnings
my $time_end = time;
my $elapsedtime = $time_end - $time_start;
$report->{seconds} = $elapsedtime;

my @warning = ();
my @critical = ();

push @warning, "most recent received $report->{delay} seconds ago" if( defined($report->{delay}) && $report->{delay} > $delay_warn );
push @critical, "most recent received $report->{delay} seconds ago" if( defined($report->{delay}) && $report->{delay} > $delay_crit );
push @warning, "no emails found" if( !defined($report->{delay}) );

# print report and exit with known status
my $perf_data = "delay=".$report->{delay}."s;$delay_warn;$delay_crit;0 elapsed=".$report->{seconds}."s"; # TODO: need a component for safely generating valid perf data format. for notes on the format, see http://www.perfparse.de/tiki-view_faq.php?faqId=6
my $short_report = $report->text(qw/seconds delay/) . " | $perf_data";
my $long_report = join("", map { "$_: $report->{$_}\n" } @report_plugins );
if( scalar @critical ) {
	my $alerts = join(", ", @critical);
	print "EMAIL DELIVERY CRITICAL - $alerts; $short_report\n";
	print $long_report if $verbose;
	exit $status{CRITICAL};
}
if( scalar @warning ) {
	my $alerts = join(", ", @warning);
	print "EMAIL DELIVERY WARNING - $alerts; $short_report\n";
	print $long_report if $verbose;
	exit $status{WARNING};
}
print "EMAIL DELIVERY OK - $short_report\n";
print $long_report if $verbose;
exit $status{OK};

# utility to load required modules. exits if unable to load one or more of the modules.
sub load_modules {
	my @missing_modules = ();
	foreach( @_ ) {
		eval "require $_";
		push @missing_modules, $_ if $@;	
	}
	if( @missing_modules ) {
		print "Missing perl modules: @missing_modules\n";
		return 0;
	}
	return 1;
}

# returns one random character from a set of characters
sub pick_random {
	my @set = @_;
	my $size = scalar @set;
	my $string = $set[int(rand($size))];
	return $string;
}

# appens tokens and times to a tab-separated value file
sub record_tokens {
	my ($tokenfile,$tokens,$time_start,$time_end,$status,$plugin_num,$output) = @_;
	if( $tokenfile ) {
		my @tokens = @$tokens;
		$time_end = "" unless defined $time_end;
		$status = "" unless defined $status;
		$plugin_num = "" unless defined $plugin_num;
		$output = "" unless defined $output;
		print "saving ".scalar(@tokens)." tokens into $tokenfile\n" if $verbose;
		open(TOKENFILE,">>$tokenfile");
		foreach(@tokens) {
			print TOKENFILE "$_\t$time_start\t$time_end\t$status\t$plugin_num\t$output\n";
		}
		close(TOKENFILE);
	}
}

# NAME
#	PluginReport
# SYNOPSIS
#	$report = new PluginReport;
#   $report->{label1} = "value1";
#   $report->{label2} = "value2";
#	print $report->text(qw/label1 label2/);
package PluginReport;

sub new {
	my ($proto,%p) = @_;
	my $class = ref($proto) || $proto;
	my $self  = bless {}, $class;
	$self->{$_} = $p{$_} foreach keys %p;
	return $self;
}

sub text {
	my ($self,@labels) = @_;
	my @report = map { "$self->{$_} $_" } grep { defined $self->{$_} } @labels;
	my $text = join(", ", @report);
	return $text;
}

package main;
1;

__END__

=pod

=head1 NAME

check_email_delivery - sends email and verifies delivery

=head1 SYNOPSIS

 check_email_delivery -vV
 check_email_delivery --usage
 check_email_delivery --help

=head1 OPTIONS

=over

=item --warning <seconds>[,<smtp_seconds>,<imap_seconds>]

Exit with WARNING if the most recent email found is older than <seconds>. The
optional <smtp_seconds> and <imap_seconds> parameters will be passed on to the
included plugins that are used for those tasks. If they are not
given then they will not be passed on and the default for that plugin will apply.
Also known as: -w <seconds>[,<send>[,<recv>]]

When using the --plugin option, only one parameter is supported (-w <seconds>) and it will apply
to the entire process. You can specify a warning threshold specific to each plugin in the 
plugin command line. 

When using the --plugin option, no measuring of "most recent email" is done because we would
not know how to read this information from receive plugins. This may be addressed in future versions.

=item --critical <seconds>[,<smtp_seconds>,<imap_seconds>]

Exit with CRITICAL if the most recent email found is older than <seconds>. The
optional <smtp_seconds> and <imap_seconds> parameters will be passed on to the
included plugins that are used for those tasks. If they are not
given then they will not be passed on and the default for that plugin will apply.
Also known as: -c <seconds>[,<send>[,<recv>]]

When using the --plugin option, only one parameter is supported (-c <seconds>) and it will apply
to the entire process. You can specify a critical threshold specific to each plugin in the 
plugin command line. 

When using the --plugin option, no measuring of "most recent email" is done because we would
not know how to read this information from receive plugins. This may be addressed in future versions.

=item --timeout <seconds>

=item --timeout <smtp_seconds>,<imap_seconds>

=item --timeout <plugin1_seconds>,<plugin2_seconds>,...

Exit with CRITICAL if the plugins do not return a status within the specified number of seconds.
When only one parameter is used, it applies to each plugin. When multiple parameters are used
(separated by commas) they apply to plugins in the same order the plugins were specified on the
command line. When using --timeout but not the --plugin option, the first parameter is for 
check_smtp_send and the second is for check_imap_receive. 

=item --alert <pluginN>

Exit with WARNING or CRITICAL only if a warning or error (--warning, --critical, or --timeout)
occurs for specified plugins. If a warning or error occurs for non-specified plugins that run
BEFORE the specified plugins, the exit status will be UNKNOWN.  If a warning of error occurs
for non-specified plugins that run AFTER the specified plugins, the exit status will not be
affected. 

You would use this option if you are using check_email_delivery with the --plugin option and
the plugins you configure each use different servers, for example different SMTP and IMAP servers.
By default, if you do not use the --alert option, if anything goes wrong during the email delivery
check, a WARNING or CRITICAL alert will be issued. This means that if you define check_email_delivery
for the SMTP server only and the IMAP server fails, Nagios will alert you for the SMTP server which
would be misleading. If you define it for both the SMTP server and IMAP server and just one of them
fails, Nagios will alert you for both servers, which would still be misleading.  If you have this
situation, you may want to use the --alert option. You define the check_email_delivery check for
both servers:  for the SMTP server (first plugin) you use --alert 1, and for for the IMAP server
(second plugin) you use --alert 2. When check_email_delivery runs with --alert 1 and the SMTP
server fails, you will get the appropriate alert. If the IMAP server fails it will not affect the
status. When check_email_delivery runs with --alert 2 and the SMTP server fails, you will get the
UNKNOWN return code. If the IMAP server generates an alert you will get a WARNING or CRITICAL as
appropriate. 

You can repeat this option to specify multiple plugins that should cause an alert.
Do this if you have multiple plugins on the command line but some of them involve the same server.

See also: --plugin.
Also known as: -A <pluginN>


=item --wait <seconds>[,<seconds>,...]

How long to wait between sending the message and checking that it was received. View default with
the -vV option.

When using the --plugin option, you can specify as many wait-between times as you have plugins
(minus the last plugin, because it makes no sense to wait after running the last one). For
example, if you use the --plugin option twice to specify an SMTP plugin and an IMAP plugin, and
you want to wait 5 seconds between sending and receiving, then you would specify --wait 5. A second
example, if you are using the --plugin option three times, then specifying -w 5 will wait 5 seconds
between the second and third plugins also. You can specify a different wait time
of 10 seconds between the second and third plugins, like this:  -w 5,10. 

=item --hostname <server>

Address or name of the SMTP and IMAP server. Examples: mail.server.com, localhost, 192.168.1.100.
Also known as: -H <server>

=item --smtp-server <server>

Address or name of the SMTP server. Examples: smtp.server.com, localhost, 192.168.1.100.
Using this option overrides the hostname option.

=item --smtp-port <number>

Service port on the SMTP server. Default is 25.

=item --smtp-username <username>

=item --smtp-password <password>

Username and password to use when connecting to the SMTP server.
Use these options if the SMTP account has a different username/password than the
IMAP account you are testing. These options take precendence over the --username and
the --password options.

=item --imap-server <server>

Address or name of the IMAP server. Examples: imap.server.com, localhost, 192.168.1.100.
Using this option overrides the hostname option.

=item --imap-port <number>

Service port on the IMAP server. Default is 143. If you use SSL the default is 993.

=item --imap-username <username>

=item --imap-password <password>

Username and password to use when connecting to the IMAP server.
Use these options if the IMAP account has a different username/password than the
SMTP account you are testing. These options take precendence over the --username and
the --password options.

=item --username <username>

=item --password <password>

Username and password to use when connecting to IMAP and SMTP server. 
Also known as: -U <username> -P <password>

To specify a separate set of credentials for SMTP authentication, see the
options --smtp-username and --smtp-password.

To specify a separate set of credentials for IMAP authentication, see the
options --imap-username and --imap-password.

=item --imap-check-interval <seconds>

How long to wait between polls of the imap-server for the specified mail. Default is 5 seconds.

=item --imap-retries <times>

How many times to poll the imap-server for the mail, before we give up. Default is 10. 

=item --body <message>

Use this option to specify the body of the email message.

=item --header <header>

Use this option to set an arbitrary header in the message. You can use it multiple times.

=item --mailto recipient@your.net

You can send a message to multiple recipients by repeating this option or by separating
the email addresses with commas (no whitespace allowed): 

$ check_email_delivery ... --mailto recipient@your.net,recipient2@your.net --mailfrom sender@your.net 

=item --mailfrom sender@your.net

Use this option to set the "from" address in the email.

=item --imapssl
=item --noimapssl

Use this to enable or disable SSL for the IMAP plugin. 

=item --smtptls
=item --nosmtptls

Use this to enable or disable TLS for the SMTP plugin. 

=item --libexec

Use this option to set the path of the Nagios libexec directory. The default is
/usr/local/nagios/libexec. This is where this plugin looks for the SMTP and IMAP
plugins that it depends on.

=item --plugin <command>

This is a new option introduced in version 0.5 of the check_email_delivery plugin.
It frees the plugin from depending on specific external plugins and generalizes the
work done to determine that the email loop is operational. When using the --plugin
option, the following options are ignored: libexec, imapssl, smtptls, hostname, 
username, password, smtp*, imap*, mailto, mailfrom, body, header, search.

Use this option multiple times to specify the complete trip. Typically, you would use
this twice to specify plugins for SMTP and IMAP, or SMTP and POP3.

The output will be success if all the plugins return success. Each plugin should be a
standard Nagios plugin. 

A random token will be automatically generated and passed to each plugin specified on
the command line by substituting the string $TOKEN1$. 

Example usage:

 command_name check_email_delivery
 command_line check_email_delivery
 --plugin "$USER1$/check_smtp_send -H $ARG1$ --mailto recipient@your.net --mailfrom sender@your.net --header 'Subject: Nagios Test %TOKEN1%.'"
 --plugin "$USER1$/check_imap_receive -H $ARG1$ -U $ARG1$ -P $ARG2$ -s SUBJECT -s 'Nagios Test %TOKEN1%.'"

This technique allows for a lot of flexibility in configuring the plugins that test
each part of your email delivery loop. 

See also: --token.
Also known as: -p <command>

=item --token <format>

This is a new option introduced in version 0.5 of the check_email_delivery plugin.
It can be used in conjunction with --plugin to control the tokens that are generated
and passed to the plugins, like %TOKEN1%.

Use this option multiple times to specify formats for different tokens. For example,
if you want %TOKEN1% to consist of only alphabetical characters but want %TOKEN2% to
consist of only digits, then you might use these options: --token aaaaaa --token nnnnn

Any tokens used in your plugin commands that have not been specified by --token <format> 
will default to --token U-X-Y

Token formats:
a - alpha character (a-z)
n - numeric character (0-9)
c - alphanumeric character (a-z0-9)
h - hexadecimal character (0-9a-f)
U - unix time, seconds from epoch. eg 1193012441
X - a word from the pgp even list. eg aardvark
Y - a word from the pgp odd list. eg adroitness

Caution: It has been observed that some IMAP servers do not handle underscores well in the
search criteria. For best results, avoid using underscores in your tokens. Use hyphens or commas instead. 

See also: --plugin.
Also known as: -T <format>

The PGP word list was obtained from http://en.wikipedia.org/wiki/PGP_word_list

=item --file <file>

Save (append) status information into the given tab-delimited file. Format used:

 token	start-time	end-time	status	plugin-num	output

Note: format may change in future versions and may become configurable.

This option available as of version 0.6.2.

Also known as: -F <file>

=item --verbose

Display additional information. Useful for troubleshooting. Use together with --version to see the default
warning and critical timeout values.
Also known as: -v

=item --version

Display plugin version and exit.
Also known as: -V

=item --help

Display this documentation and exit. Does not work in the ePN version. 
Also known as: -h

=item --usage

Display a short usage instruction and exit. 

=back

=head1 EXAMPLES

=head2 Send a message with custom headers

$ check_email_delivery -H mail.server.net --mailto recipient@your.net --mailfrom sender@your.net 
--username recipient --password secret

EMAIL DELIVERY OK - 1 seconds

=head2 Set warning and critical timeouts for receive plugin only:

$ check_email_delivery -H mail.server.net --mailto recipient@your.net --mailfrom sender@your.net 
--username recipient --password secret -w ,,5 -c ,,15

EMAIL DELIVERY OK - 1 seconds

=head1 EXIT CODES

Complies with the Nagios plug-in specification:
 0		OK			The plugin was able to check the service and it appeared to be functioning properly
 1		Warning		The plugin was able to check the service, but it appeared to be above some "warning" threshold or did not appear to be working properly
 2		Critical	The plugin detected that either the service was not running or it was above some "critical" threshold
 3		Unknown		Invalid command line arguments were supplied to the plugin or the plugin was unable to check the status of the given hosts/service

=head1 NAGIOS PLUGIN NOTES

Nagios plugin reference: http://nagiosplug.sourceforge.net/developer-guidelines.html

This plugin does NOT use Nagios DEFAULT_SOCKET_TIMEOUT (provided by utils.pm as $TIMEOUT) because
the path to utils.pm must be specified completely in this program and forces users to edit the source
code if their install location is different (if they realize this is the problem). You can view
the default timeout for this module by using the --verbose and --version options together.  The
short form is -vV.

Other than that, it attempts to follow published guidelines for Nagios plugins.

=head1 CHANGES

 Wed Oct 29 13:08:00 PST 2005
 + version 0.1

 Wed Nov  9 17:16:09 PST 2005
 + updated arguments to check_smtp_send and check_imap_receive
 + added eval/alarm block to implement -c option
 + added wait option to adjust sleep time between smtp and imap calls
 + added delay-warn and delay-crit options to adjust email delivery warning thresholds
 + now using an inline PluginReport package to generate the report
 + copyright notice and GNU GPL
 + version 0.2

 Thu Apr 20 14:00:00 CET 2006 (by Johan Nilsson <johann (at) axis.com>)
 + version 0.2.1
 + corrected bug in getoptions ($imap_server would never ever be set from command-line...)
 + will not make $smtp_server and $imap_server == $host if they're defined on commandline 
 + added support for multiple polls of imap-server, with specified intervals
 + changed default behaviour in check_imap_server (searches for the specific id in subject and deletes mails found)
 + increased default delay_warn from 65 seconds to 95 seconds 

 Thu Apr 20 16:00:00 PST 2006 (by Geoff Crompton <geoff.crompton@strategicdata.com.au>)
 + fixed a bug in getoptions
 + version 0.2.2

 Tue Apr 24 21:17:53 PDT 2007
 + now there is an alternate version (same but without embedded perl POD) that is compatible with the new new embedded-perl Nagios feature
 + version 0.2.3

 Fri Apr 27 20:32:53 PDT 2007 
 + documentation now mentions every command-line option accepted by the plugin, including abbreviations
 + changed connection error to display timeout only if timeout was the error
 + default IMAP plugin is libexec/check_imap_receive (also checking for same but with .pl extension)
 + default SMTP plugin is libexec/check_smtp_send (also checking for same but with .pl extension)
 + removed default values for SMTP port and IMAP port to allow those plugins to set the defaults; so current behavior stays the same and will continue to make sense with SSL
 + version 0.3

 Thu Oct 11 10:00:00 EET 2007 (by Timo Virtaneva <timo (at) virtaneva dot com>
 + Changed the header and the search criteria so that the same email-box can be used for all smtp-servers
 + version 0.3.1

 Sun Oct 21 11:01:03 PDT 2007
 + added support for TLS options to the SMTP plugin
 + version 0.4

 Sun Oct 21 16:17:14 PDT 2007
 + added support for arbitrary plugins to send and receive mail (or anthing else!). see the --plugin option.
 + version 0.5

 Tue Dec  4 07:36:20 PST 2007
 + added --usage option because the official nagios plugins have both --help and --usage
 + added --timeout option to match the official nagios plugins
 + shortcut option for --token is now -T to avoid clash with standard shortcut -t for --timeout
 + fixed some minor pod formatting issues for perldoc
 + version 0.5.1

 Sat Dec 15 07:39:59 PST 2007
 + improved compatibility with Nagios embedded perl (ePN)
 + version 0.5.2

 Thu Jan 17 20:27:36 PST 2008 (by Timo Virtaneva <timo (at) virtaneva dot com> on Thu Oct 11 10:00:00 EET 2007)
 + Changed the header and the search criteria so that the same email-box can be used for all smtp-servers
 + version 0.5.3

 Mon Jan 28 22:11:02 PST 2008
 + fixed a bug, smtp-password and imap-password are now string parameters
 + added --alert option to allow selection of which plugin(s) should cause a WARNING or CRITICAL alert
 + version 0.6

 Mon Feb 11 19:09:37 PST 2008
 + fixed a bug for embedded perl version, variable "%status" will not stay shared in load_modules
 + version 0.6.1

 Mon May 26 10:39:19 PDT 2008
 + added --file option to allow plugin to record status information into a tab-delimited file
 + changed default token from U_X_Y to U-X-Y 
 + version 0.6.2

 Wed Jan 14 08:29:35 PST 2009
 + fixed a bug that the --header parameter was not being passed to the smtp plugin.
 + version 0.6.3

 Mon Jun  8 15:43:48 PDT 2009
 + added performance data for use with PNP4Nagios! (thanks to Ben Ritcey for the patch)
 + version 0.6.4

 Wed Sep 16 07:10:10 PDT 2009
 + added elapsed time in seconds to performance data
 + version 0.6.5


=head1 AUTHOR

Jonathan Buhacoff <jonathan@buhacoff.net>

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2005-2010 Jonathan Buhacoff

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

 http://www.gnu.org/licenses/gpl.txt

=cut
