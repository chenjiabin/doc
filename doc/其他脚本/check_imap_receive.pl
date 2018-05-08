#!/usr/bin/perl
use strict;
use lib "/opt/plugins/utils";
my $VERSION = '0.7.3';
my $COPYRIGHT = 'Copyright (C) 2005-2010 Jonathan Buhacoff <jonathan@buhacoff.net>';
my $LICENSE = 'http://www.gnu.org/licenses/gpl.txt';
my %status = ( 'OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2, 'UNKNOWN' => 3 );

# look for required modules
exit $status{UNKNOWN} unless load_modules(qw/Getopt::Long Mail::IMAPClient/);

# get options from command line
Getopt::Long::Configure("bundling");
my $verbose = 0;
my $help = "";
my $help_usage = "";
my $show_version = "";
my $imap_server = "";
my $default_imap_port = "143";
my $default_imap_ssl_port = "993";
my $imap_port = "";
my $username = "";
my $password = "";
my $mailbox = "INBOX";
my @search = ();
my $search_critical_min = 1;
my $search_critical_max = -1; # -1 means disabled for this option
my $search_warning_min = 1;
my $search_warning_max = -1; # -1 means disabled for this option
my $capture_max = "";
my $capture_min = "";
my $delete = 1;
my $no_delete_captured = "";
my $warntime = 15;
my $criticaltime = 30;
my $timeout = 60;
my $interval = 5;
my $max_retries = 10;
my $download = "";
my $download_max = "";
my $peek = "";
my $template = "";
my $ssl = 0;
my $tls = 0;
my $ok;
$ok = Getopt::Long::GetOptions(
	"V|version"=>\$show_version,
	"v|verbose+"=>\$verbose,"h|help"=>\$help,"usage"=>\$help_usage,
	"w|warning=i"=>\$warntime,"c|critical=i"=>\$criticaltime,"t|timeout=i"=>\$timeout,
	# imap settings
	"H|hostname=s"=>\$imap_server,"p|port=i"=>\$imap_port,
	"U|username=s"=>\$username,"P|password=s"=>\$password, "m|mailbox=s"=>\$mailbox,
	"imap-check-interval=i"=>\$interval,"imap-retries=i"=>\$max_retries,
	"ssl!"=>\$ssl, "tls!"=>\$tls,
	# search settings
	"s|search=s"=>\@search,
	"search-critical-min=i"=>\$search_critical_min, "search-critical-max=i"=>\$search_critical_max,
	"search-warning-min=i"=>\$search_warning_min, "search-warning-max=i"=>\$search_warning_max,
	"capture-max=s"=>\$capture_max, "capture-min=s"=>\$capture_min,
	"delete!"=>\$delete, "nodelete-captured"=>\$no_delete_captured,
	"download!"=>\$download, "download_max=i"=>\$download_max, "download-max=i"=>\$download_max,
	"peek!"=>\$peek,
	"template!"=>\$template
	);

if( $show_version ) {
	print "$VERSION\n";
	if( $verbose ) {
		print "Default warning threshold: $warntime seconds\n";
		print "Default critical threshold: $criticaltime seconds\n";
		print "Default timeout: $timeout seconds\n";
	}
	exit $status{UNKNOWN};
}

if( $help ) {
	exec "perldoc", $0 or print "Try `perldoc $0`\n";
	exit $status{UNKNOWN};
}

my @required_module = ();
push @required_module, 'IO::Socket::SSL' if $ssl || $tls;
push @required_module, 'Email::Simple' if $download;
push @required_module, ('Text::Template','Date::Manip') if $template;
exit $status{UNKNOWN} unless load_modules(@required_module);

if( $help_usage
	||
	( $imap_server eq "" || $username eq "" || $password eq "" || scalar(@search)==0 )
  ) {
	print "Usage: $0 -H host [-p port] -U username -P password -s HEADER -s X-Nagios -s 'ID: 1234.' [-w <seconds>] [-c <seconds>] [--imap-check-interval <seconds>] [--imap-retries <tries>]\n";
	exit $status{UNKNOWN};
}

# before attempting to connect to the server, check if any of the search parameters
# use substitution functions and make sure we can parse them first. if we can't we
# need to abort since the search will be meaningless.
if( $template ) {
	foreach my $token (@search) {
		my $t = Text::Template->new(TYPE=>'STRING',SOURCE=>$token,PACKAGE=>'ImapSearchTemplate');
		$token = $t->fill_in(PREPEND=>q{package ImapSearchTemplate;});
		#print "token: $token\n";
	}
}


# initialize
my $report = new PluginReport;
my $time_start = time;

# connect to IMAP server
print "connecting to server $imap_server\n" if $verbose > 2;
my $imap;
eval {
	local $SIG{ALRM} = sub { die "exceeded timeout $timeout seconds\n" }; # NB: \n required, see `perldoc -f alarm`
	alarm $timeout;
	
	if( $ssl ) {
		$imap_port = $default_imap_ssl_port unless $imap_port;		
		my $socket = IO::Socket::SSL->new("$imap_server:$imap_port");
		die IO::Socket::SSL::errstr() unless $socket;
		$socket->autoflush(1);
		$imap = Mail::IMAPClient->new(Socket=>$socket, Debug => 0 );
		$imap->State(Mail::IMAPClient->Connected);
		$imap->_read_line() if "$Mail::IMAPClient::VERSION" le "2.2.9"; # necessary to remove the server's "ready" line from the input buffer for old versions of Mail::IMAPClient. Using string comparison for the version check because the numeric didn't work on Darwin and for Mail::IMAPClient the next version is 2.3.0 and then 3.00 so string comparison works
		$imap->User($username);
		$imap->Password($password);
		$imap->login() or die "$@";
	}
	elsif( $tls ) {
		# XXX  THIS PART IS NOT DONE YET ... NEED TO OPEN A REGULAR IMAP CONNECTION, THEN ISSUE THE "STARTTLS" COMMAND MANUALLY, SWITCHING THE SOCKET TO IO::SOCKET::SSL, AND THEN GIVING IT BACK TO MAIL::IMAPCLIENT ...
		$imap_port = $default_imap_port unless $imap_port;		
		$imap = Mail::IMAPClient->new(Debug => 0 );		
		$imap->Server("$imap_server:$imap_port");
		$imap->User($username);
		$imap->Password($password);
		$imap->connect() or die "$@";		
	}
	else {
		$imap_port = $default_imap_port unless $imap_port;		
		$imap = Mail::IMAPClient->new(Debug => 0 );		
		$imap->Server("$imap_server:$imap_port");
		$imap->User($username);
		$imap->Password($password);
		$imap->connect() or die "$@";
	}

	$imap->Peek(1) if $peek;
	$imap->Ignoresizeerrors(1);

	alarm 0;
};
if( $@ ) {
	chomp $@;
	print "IMAP RECEIVE CRITICAL - Could not connect to $imap_server port $imap_port: $@\n";
	exit $status{CRITICAL};	
}
unless( $imap ) {
	print "IMAP RECEIVE CRITICAL - Could not connect to $imap_server port $imap_port: $@\n";
	exit $status{CRITICAL};
}
my $time_connected = time;

# select a mailbox
print "selecting mailbox $mailbox\n" if $verbose > 2;
unless( $imap->select($mailbox) ) {
	print "IMAP RECEIVE CRITICAL - Could not select $mailbox: $@ $!\n";
	if( $verbose > 2 ) {
		print "Mailbox list:\n" . join("\n", $imap->folders) . "\n";
		print "Mailbox separator: " . $imap->separator . "\n";
		##print "Special mailboxes:\n" . join("\n", map { "$_ => ".
	}
	$imap->logout();
	exit $status{CRITICAL};
}


# search for messages
my $tries = 0;
my @msgs;
until( scalar(@msgs) != 0 || $tries >= $max_retries ) {
	eval {
		$imap->select( $mailbox );
		# if download flag is on, we download recent messages and search ourselves
		if( $download )  {
			print "downloading messages to search\n" if $verbose > 2;
			@msgs = download_and_search($imap,@search);
		}
		else {
			print "searching on server\n" if $verbose > 2;
			@msgs = $imap->search(@search);
			die "Invalid search parameters: $@" if $@;
		}
	};
	if( $@ ) {
		chomp $@;
		print "Cannot search messages: $@\n";
		$imap->close();
		$imap->logout();
		exit $status{UNKNOWN};
	}	
	$report->{found} = scalar(@msgs);
	$tries++;
	sleep $interval unless (scalar(@msgs) != 0 || $tries >= $max_retries);
}

sub download_and_search {
	my ($imap,@search) = @_;
	my $ims = new ImapMessageSearch;
	$ims->querytokens(@search);	
	my @found = ();
	@msgs = reverse $imap->messages or (); # die "Cannot list messages: $@\n"; # reversing to get descending order, which is most recent messages first! (at least on my mail servers)
	@msgs = @msgs[0..$download_max-1] if $download_max && scalar(@msgs) > $download_max;
	foreach my $m (@msgs) {
		my $message = $imap->message_string($m);
		push @found, $m if $ims->match($message);
	}
	return @found;
}



# capture data in messages
my $captured_max_id = "";
my $captured_min_id = "";
if( $capture_max || $capture_min ) {
	my $max = undef;
	my $min = undef;
	my %captured = ();
	for (my $i=0;$i < scalar(@msgs); $i++) 	{
		my $message = $imap->message_string($msgs[$i]);
		if( $message =~ m/$capture_max/ ) {
			if( !defined($max) || $1 > $max ) {
				$captured{ $i } = 1;
				$max = $1;
				$captured_max_id = $msgs[$i];
			}
		}
		if( $message =~ m/$capture_min/ ) {
			if( !defined($min) || $1 < $min ) {
				$captured{ $i } = 1;
				$min = $1;
				$captured_min_id = $msgs[$i];
			}
		}
		print $message if $verbose > 1;
	}
	$report->{captured} = scalar keys %captured;
	$report->{max} = $max if defined $max;
	$report->{min} = $min if defined $min;
}

# delete messages
if( $delete ) {
	print "deleting matching messages\n" if $verbose > 2;
	my $deleted = 0;
	for (my $i=0;$i < scalar(@msgs); $i++) 	{
		next if ($no_delete_captured && ($captured_max_id eq $msgs[$i]));
		next if ($no_delete_captured && ($captured_min_id eq $msgs[$i]));
		$imap->delete_message($msgs[$i]);
		$deleted++;
	}
	$report->{deleted} = $deleted;
	$imap->expunge() if $deleted;
}

# deselect the mailbox
$imap->close();

# disconnect from IMAP server
print "disconnecting from server\n" if $verbose > 2;
$imap->logout();

# calculate elapsed time and issue warnings
my $time_end = time;
my $elapsedtime = $time_end - $time_start;
$report->{seconds} = $elapsedtime;
$report->{found} = 0 unless defined $report->{found};
$report->{captured} = 0 unless defined $report->{captured};

my @warning = ();
my @critical = ();

push @warning, "found less than $search_warning_min" if( scalar(@msgs) < $search_warning_min );
push @warning, "found more than $search_warning_max" if ( $search_warning_max > -1 && scalar(@msgs) > $search_warning_max );
push @critical, "found less than $search_critical_min" if ( scalar(@msgs) < $search_critical_min );
push @critical, "found more than $search_critical_max" if ( $search_critical_max > -1 && scalar(@msgs) > $search_critical_max );
push @warning, "connection time more than $warntime" if( $time_connected - $time_start > $warntime );
push @critical, "connection time more than $criticaltime" if( $time_connected - $time_start > $criticaltime );

# print report and exit with known status
my $perf_data = "elapsed=".$report->{seconds}."s found=".$report->{found}."messages captured=".$report->{captured}."messages"; # TODO: need a component for safely generating valid perf data format. for notes on the format, see http://www.perfparse.de/tiki-view_faq.php?faqId=6 and http://nagiosplug.sourceforge.net/developer-guidelines.html#AEN185
my $short_report = $report->text(qw/seconds found captured max min deleted/) . " | $perf_data";
if( scalar @critical ) {
	my $crit_alerts = join(", ", @critical);
	print "IMAP RECEIVE CRITICAL - $crit_alerts; $short_report\n";
	exit $status{CRITICAL};
}
if( scalar @warning ) {
	my $warn_alerts = join(", ", @warning);
	print "IMAP RECEIVE WARNING - $warn_alerts; $short_report\n";
	exit $status{WARNING};
}
print "IMAP RECEIVE OK - $short_report\n";
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

package ImapMessageSearch;

require Email::Simple;

sub new {
	my ($proto,%p) = @_;
	my $class = ref($proto) || $proto;
	my $self  = bless {}, $class;
	$self->{querystring} = [];
	$self->{querytokens} = [];
	$self->{queryfnlist} = [];
	$self->{mimemessage} = undef;
	$self->{$_} = $p{$_} foreach keys %p;
	return $self;
}

sub querystring {
	my ($self,$string) = @_;
	$self->{querystring} = $string;
	return $self->querytokens( parseimapsearch($string) );
}

sub querytokens {
	my ($self,@tokens) = @_;
	$self->{querytokens} = [@tokens];
	$self->{queryfnlist} = [create_search_expressions(@tokens)]; 
	return $self;
}

sub match {
	my ($self,$message_string) = @_;
	return 0 unless defined $message_string;
	my $message_mime = Email::Simple->new($message_string);
	return $self->matchmime($message_mime);
}

sub matchmime {
	my ($self,$message_mime) = @_;
	my $match = 1;
	foreach my $x (@{$self->{queryfnlist}}) {
		$match = $match && $x->($message_mime);
	}
	return $match;
}

# this should probably become its own Perl module... see also Net::IMAP::Server::Command::Search
sub create_search_expressions {
	my (@search) = @_;
	return () unless scalar(@search);
	my $token = shift @search;
	if( $token eq 'TEXT' ) {
		my $value = shift @search;
		return (sub {shift->as_string =~ /\Q$value\E/i},create_search_expressions(@search));
	}
	if( $token eq 'BODY' ) {
		my $value = shift @search;
		return (sub {shift->body =~ /\Q$value\E/i},create_search_expressions(@search));
	}
	if( $token eq 'SUBJECT' ) {
		my $value = shift @search;
		return (sub {shift->header('Subject') =~ /\Q$value\E/i},create_search_expressions(@search));		
	}
	if( $token eq 'HEADER' ) {
		my $name = shift @search;
		my $value = shift @search;
		return (sub {shift->header($name) =~ /\Q$value\E/i},create_search_expressions(@search));				
	}
	if( $token eq 'NOT' ) {
		my @exp = create_search_expressions(@search);
		my $next = shift @exp;
		return (sub { ! $next->(@_) }, @exp);
	}
	if( $token eq 'OR' ) {
		my @exp = create_search_expressions(@search);
		my $next1 = shift @exp;
		my $next2 = shift @exp;
		return (sub { $next1->(@_) or $next2->(@_) }, @exp);
	}
	if( $token eq 'SENTBEFORE' ) {
		my $value = shift @search;
		return (sub {datecmp(shift->header('Date'),$value) < 0},create_search_expressions(@search));		
	}
	if( $token eq 'SENTON' ) {
		my $value = shift @search;
		return (sub {datecmp(shift->header('Date'),$value) == 0},create_search_expressions(@search));		
	}
	if( $token eq 'SENTSINCE' ) {
		my $value = shift @search;
		return (sub {datecmp(shift->header('Date'),$value) > 0},create_search_expressions(@search));		
	}
	return sub { die "invalid search parameter: $token" };
}

sub datecmp {
	my ($date1,$date2) = @_;
	my $parsed1 = Date::Manip::ParseDate($date1);
	my $parsed2 = Date::Manip::ParseDate($date2);
	my $cmp = Date::Manip::Date_Cmp($parsed1,$parsed2);
	print " $date1  <=>   $date2    ->  $cmp\n";
	return $cmp <=> 0;
}

package ImapSearchTemplate;

# Takes an English date specification ("now", etc) and an optional offset ("-4 hours")
# and returns an RFC 2822 formatted date string.
# see http://search.cpan.org/dist/Date-Manip/lib/Date/Manip.pod
sub rfc2822dateHeader {
	my ($when,$delta) = @_;
	$when = Date::Manip::ParseDate($when);
	$delta = Date::Manip::ParseDateDelta($delta) if $delta;
	my $d = $delta ? Date::Manip::DateCalc($when,$delta) : $when;
	return Date::Manip::UnixDate($d, "%a, %d %b %Y %H:%M:%S %z");
}

sub rfc2822date {
	my ($when,$delta) = @_;
	$when = Date::Manip::ParseDate($when);
	$delta = Date::Manip::ParseDateDelta($delta) if $delta;
	my $d = $delta ? Date::Manip::DateCalc($when,$delta) : $when;
	return Date::Manip::UnixDate($d, "%d-%b-%Y");
}

# alias for 2822 ... RFC 822 is an older version and specifies 2-digit years, but we ignore that for now.
sub rfc822dateHeader { return rfc2822dateHeader(@_); }
sub rfc822date { return rfc2822date(@_); }

sub date {
	my ($format,$when,$delta) = @_;
	$when = Date::Manip::ParseDate($when);
	$delta = Date::Manip::ParseDateDelta($delta) if $delta;
	my $d = $delta ? Date::Manip::DateCalc($when,$delta) : $when;
	return Date::Manip::UnixDate($d, $format);
}

package main;
1;

__END__


=pod

=head1 NAME

check_imap_receive - connects to and searches an IMAP account for messages

=head1 SYNOPSIS

 check_imap_receive -vV
 check_imap_receive -?
 check_imap_receive --help

=head1 OPTIONS

=over

=item --warning <seconds>

Warn if it takes longer than <seconds> to connect to the IMAP server. Default is 15 seconds.
Also known as: -w <seconds>

=item --critical <seconds>

Return a critical status if it takes longer than <seconds> to connect to the IMAP server. Default is 30 seconds.
See also: --capture-critical <messages>
Also known as: -c <seconds>

=item --timeout <seconds>

Abort with critical status if it takes longer than <seconds> to connect to the IMAP server. Default is 60 seconds.
The difference between timeout and critical is that, with the default settings, if it takes 45 seconds to 
connect to the server then the connection will succeed but the plugin will return CRITICAL because it took longer
than 30 seconds.
Also known as: -t <seconds> 

=item --imap-check-interval <seconds>

How long to wait after searching for a matching message before searching again. Only takes effect
if no messages were found.  Default is 5 seconds.

=item --imap-retries <number>

How many times to try searching for a matching message before giving up. If you set this to 0 then
messages will not be searched at all. Setting this to 1 means the plugin only tries once. Etc.
Default is 10 times.

=item --hostname <server>

Address or name of the IMAP server. Examples: mail.server.com, localhost, 192.168.1.100
Also known as: -H <server>

=item --port <number>

Service port on the IMAP server. Default is 143. If you use SSL, default is 993.
Also known as: -p <number>

=item --username <username>

=item --password <password>

Username and password to use when connecting to IMAP server. 
Also known as: -U <username> -P <password>

=item --mailbox <mailbox>

Use this option to specify the mailbox to search for messages. Default is INBOX. 
Also known as: -m <mailbox>

=item --search <string>

Use this option to filter the messages. Default is not to filter. You may (must) use this option
multiple times in order to create any valid IMAP search criteria. See the examples and see also
http://www.ietf.org/rfc/rfc2060.txt (look for section 6.4.4, the SEARCH command)

This is the way to find messages matching a given subject:
 -s SUBJECT -s "a given subject"

You can use the following technique for any header, including Subject. To find "Header-Name: some value":
 -s HEADER -s Header-Name -s "some value"

Also known as: -s <string>

=item --download

=item --nodownload

This option causes all messages in the specified mailbox to be downloaded from the server
and searched locally. See --download-max if you only want to download a few messages.
Currently only the following RFC 2060 search criteria are supported:
TEXT, BODY, SUBJECT, HEADER, NOT, OR, SENTBEFORE, SENTON, SENTSINCE. 

Requires Email::Simple to be installed. It is available on CPAN.

This option may be particularly useful to you if your mail server is slow to index
messages (like Exchange 2003), causing the plugin not to find them with IMAP SEARCH 
even though they are in the inbox. 

It's also useful if you're searching for messages that have been on the server for a 
specified amount of time, like some minutes or hours, because the standard IMAP search
function only allows whole dates. For this, use the standard search keywords but you
can specify either just a date like in RFC 2060 or a date and a time.

If you use any of the date search keywords, you must have Date::Manip installed
on your system: SENTBEFORE, SENTON, SENTSINCE.


=item --download-max

Limits the number of messages downloaded from the server when the --download option is used.
Default is to download and search all messages.

=item --search-critical-min <messages>

This option will trigger a CRITICAL status if the number of messages found by the search criteria
is below the given number. Use in conjunction with --search.

This parameter defaults to 1 so that if no messages are found, the plugin will exit with a CRITICAL status.

If you want the original behavior where the plugin exits with a WARNING status when no messages are found,
set this parameter to 0.

=item --search-critical-max <messages>

This option will trigger a CRITICAL status if the number of messages found by the search criteria
is above the given number. Use in conjunction with --search.

This parameter defaults to -1 meaning it's disabled. If you set it to 10, the plugin will exit with
CRITICAL if it finds 11 messages. If you set it to 1, the plugin will exit with CRITICAL if it finds
any more than 1 message. If you set it to 0, the plugin will exit with CRITICAL if it finds any messages
at all. If you set it to -1 it will be disabled. 

=item --search-warning-min <messages>

This option will trigger a WARNING status if the number of messages found by the search criteria
is below the given number. Use in conjunction with --search.

This parameter defaults to 1 so that if no messages are found, the plugin will exit with a WARNING status.

If you want to suppress the original behavior where the plugin exits with a WARNING status when no messages are found,
set this parameter to 0. When this parameter is 0, it means that you expect the mailbox not to have any messages.

=item --search-warning-max <messages>

This option will trigger a WARNING status if the number of messages found by the search criteria
is above the given number. Use in conjunction with --search.

This parameter defaults to -1 meaning it's disabled. If you set it to 10, the plugin will exit with
WARNING if it finds 11 messages. If you set it to 1, the plugin will exit with WARNING if it finds
any more than 1 message. If you set it to 0, the plugin will exit with WARNING if it finds any messages
at all. If you set it to -1 it will be disabled. 

=item --capture-max <regexp>

In addition to specifying search arguments to filter the emails in the IMAP account, you can specify
a "capture-max" regexp argument and the eligible emails (found with search arguments)
will be compared to each other and the OK line will have the highest captured value.

The regexp is expected to capture a numeric value.

=item --capture-min <regexp>

In addition to specifying search arguments to filter the emails in the IMAP account, you can specify
a "capture-min" regexp argument and the eligible emails (found with search arguments)
will be compared to each other and the OK line will have the lowest captured value.

The regexp is expected to capture a numeric value.

=item --delete

=item --nodelete

Use the delete option to delete messages that matched the search criteria. This is useful for
preventing the mailbox from filling up with automated messages (from the check_smtp_send plugin, for example).
THE DELETE OPTION IS TURNED *ON* BY DEFAULT, in order to preserve compatibility with an earlier version.

Use the nodelete option to turn off the delete option.

=item --nodelete-captured

If you use both the capture-max and delete arguments, you can also use the nodelete-captured argument to specify that the email
with the highest captured value should not be deleted. This leaves it available for comparison the next time this plugin runs.

If you do not use the delete option, this option has no effect.

=item --ssl

=item --nossl

Enable SSL protocol. Requires IO::Socket::SSL. 

Using this option automatically changes the default port from 143 to 993. You can still
override this from the command line using the --port option.

Use the nossl option to turn off the ssl option.

=item --template

=item --notemplate

Enable (or disable) processing of IMAP search parameters. Requires Text::Template and Date::Manip. 

Use this option to apply special processing to IMAP search parameters that allows you to use the
results of arbitrary computations as the parameter values. For example, you can use this feature
to search for message received up to 4 hours ago.

When you enable the --template option, each parameter you pass to the -s option is parsed by
Text::Template. See the Text::Template manual for more information, but in general any expression
written in Perl will work. 

A convenience function called rfc2822dateHeader is provided to you so you can easily compute properly
formatted dates for use as search parameters. The rfc2822date function can take one or two
parameters itself: the date to format and an optional offset. To use the current time as a 
search parameter, you can write this:

 $ check_imap_receive ... --template -s HEADER -s Delivery-Date -s '{rfc2822dateHeader("now")}'

The output of {rfc2822dateHeader("now")} looks like this: Wed, 30 Sep 2009 22:44:03 -0700  and
is suitable for use with a date header, like HEADER Delivery-Date. 

To use a time in the past relative to the current time, you can use a second convenience function
called rfc2822date and write this:

 $ check_imap_receive ... --template -s SENTSINCE -s '{rfc2822date("now","-1 day")}'

The output of {rfc2822date("now","-1 day")} looks like this: 29-Sep-2009 and is suitable for use
with BEFORE, ON, SENTBEFORE, SENTON, SENTSINCE, and SINCE.

I have seen some email clients use a different format in the Date field,
like September 17, 2009 9:46:51 AM PDT.  To specify an arbitrary format like this one, write this:

 $ check_imap_receive ... --template -s SENTSINCE -s '{date("%B %e, %Y %i:%M:%S %p %Z","now","-4 hours")}'

See the Date::Manip manual for more information on the allowed expressions for date and delta strings.

=item --verbose

Display additional information. Useful for troubleshooting. Use together with --version to see the default
warning and critical timeout values.

If the selected mailbox was not found, you can use verbosity level 3 (-vvv) to display a list of all
available mailboxes on the server.

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

=head2 Report how many emails are in the mailbox

 $ check_imap_receive -H mail.server.net --username mailuser --password mailpass
 -s ALL --nodelete

 IMAP RECEIVE OK - 1 seconds, 7 found

=head2 Report the email with the highest value

Suppose your mailbox has some emails from an automated script and that a message
from this script typically looks like this (abbreviated):

 To: mailuser@server.net
 From: autoscript@server.net
 Subject: Results of Autoscript
 Date: Wed, 09 Nov 2005 08:30:40 -0800
 Message-ID: <auto-000000992528@server.net>

 Homeruns 5

And further suppose that you are interested in reporting the message that has the
highest number of home runs, and also to leave this message in the mailbox for future
checks, but remove the other matching messages with lesser values:

 $ check_imap_receive -H mail.server.net --username mailuser --password mailpass
 -s SUBJECT -s "Results of Autoscript" --capture-max "Homeruns (\d+)"  --nodelete-captured

 IMAP RECEIVE OK - 1 seconds, 3 found, 1 captured, 5 max, 2 deleted

=head2 Troubleshoot your search parameters

Add the --nodelete and --imap-retries=1 parameters to your command line.

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

=head1 SEE ALSO

http://nagios.org/
http://search.cpan.org/~djkernen/Mail-IMAPClient-2.2.9/IMAPClient.pod
http://search.cpan.org/~markov/Mail-IMAPClient-3.00/lib/Mail/IMAPClient.pod

=head1 CHANGES

 Wed Oct 29 11:00:00 PST 2005
 + version 0.1

 Wed Nov  9 09:53:32 PST 2005
 + added delete/nodelete option.  deleting found messages is still default behavior.
 + added capture-max option
 + added nodelete-captured option
 + added mailbox option
 + added eval/alarm block to implement -c option
 + now using an inline PluginReport package to generate the report
 + copyright notice and GNU GPL
 + version 0.2

 Thu Apr 20 14:00:00 CET 2006 (by Johan Nilsson <johann (at) axis.com>)
 + version 0.2.1
 + added support for multiple polls of imap-server, with specified intervals

 Tue Apr 24 21:17:53 PDT 2007
 + now there is an alternate version (same but without embedded perl POD) that is compatible with the new new embedded-perl Nagios feature
 + added patch from Benjamin Ritcey <ben@ritcey.com> for SSL support on machines that have an SSL-enabled
 + version 0.2.3

 Fri Apr 27 18:56:50 PDT 2007 
 + fixed problem that "Invalid search parameters" was not printed because of missing newline to flush it
 + warnings and critical errors now try to append error messages received from the IMAP client
 + changed connection error to display timeout only if timeout was the error
 + documentation now mentions every command-line option accepted by the plugin, including abbreviations
 + added abbreviations U for username, P for password, m for mailbox
 + fixed bug that imap-check-interval applied even after the last try (imap-retries) when it was not necessary
 + the IMAP expunge command is not sent unless at least one message is deleted
 + fixed bug that the "no messages" warning was printed even if some messages were found
 + version 0.3

 Sun Oct 21 14:08:07 PDT 2007
 + added port info to the "could not connect" error message
 + fixed bug that occurred when using --ssl --port 143 which caused port to remain at the default 993 imap/ssl port
 + added clarity shortcuts --search-subject and --search-header
 + port is no longer a required option. defaults to 143 for regular IMAP and 993 for IMAP/SSL
 + version 0.3.1

 Sun Oct 21 20:41:56 PDT 2007
 + reworked ssl support to use IO::Socket::SSL instead of the convenience method Mail::IMAPClient->Ssl (which is not included in the standard Mail::IMAPClient package)
 + removed clarity shortcuts (bad idea, code bloat) 
 + version 0.4

 Tue Dec  4 07:05:27 PST 2007
 + added version check to _read_line workaround for SSL-related bug in Mail::IMAPClient version 2.2.9 ; newer versions fixed the bug 
 + added --usage option because the official nagios plugins have both --help and --usage
 + added --timeout option to match the official nagios plugins
 + fixed some minor pod formatting issues for perldoc
 + version 0.4.1

 Sat Dec 15 07:39:59 PST 2007
 + improved compatibility with Nagios embedded perl (ePN)
 + version 0.4.2

 Mon Jan  7 21:35:23 PST 2008
 + changed version check for Mail::IMAPClient version 2.2.9 to use string comparison le "2.2.9"
 + fixed bug where script was dying on socket->autoflush when socket does not exist because autoflush was being called before checking the socket object 
 + version 0.4.3

 Mon Feb 11 19:13:38 PST 2008
 + fixed a bug for embedded perl version, variable "%status" will not stay shared in load_modules
 + version 0.4.4

 Mon May 26 08:33:27 PDT 2008
 + fixed a bug for number captured, it now reflects number of messages captured instead of always returning "1"
 + added --capture-min option to complement --capture-max
 + added --search-critical-min to trigger a CRITICAL alert if number of messages found is less than argument, with default 1.
 + fixed warning and critical messages to use "more than" or "less than" instead of the angle brackets, to make them more web friendly
 + version 0.5

 Wed Jul  2 14:59:05 PDT 2008
 + fixed a bug for not finding a message after the first try, by reselecting the mailbox before each search
 + version 0.5.1

 Sat Dec 13 08:57:29 PST 2008
 + added --download option to allow local searching of messages (useful if your server has an index that handles searching but it takes a while before new emails show up and you want immediate results), supports only the TEXT, BODY, SUBJECT, and HEADER search keys 
 + added --download-max option to set a limit on number of messages downloaded with --download
 + version 0.6.0

 Wed Sep 30 23:25:33 PDT 2009
 + fixed --download-max option (was incorrectly looking for --download_max). currently both will work, in the future only --download-max will work
 + added --template option to allow arbitrary substitutions for search parameters, and provided three convenience functions for working with dates
 + added date search criteria to the --download option: SENTBEFORE, SENTON, and SENTSINCE which check the Date header and allow hours and minutes in addition to dates (whereas the IMAP standard only allows dates)
 + added --search-critical-max to trigger a CRITICAL alert if number of messages found is more than argument, disabled by default.
 + fixed a bug in --download --search where messages would match even though they failed the search criteria
 + changed behavior of --download-max to look at the most recent messages first (hopefully); the IMAP protocol doesn't guarantee the order that the messages are returned but I observed that many mail servers return them in chronological order; so now --download-max reverses the order to look at the newer messages first
 + added performance data for use with PNP4Nagios!
 + version 0.7.0

 Fri Oct  2 15:22:00 PDT 2009
 + added --search-warning-max and --search-warning-min to trigger a WARNING alert if number of messages is more than or less than the specified number. 
 + fixed --download option not to fail with CRITICAL if mailbox is empty; now this can be configured with --search-warning-min or --search-critical-min
 + version 0.7.1

 Sat Nov 21 18:27:17 PST 2009
 + fixed problem with using --download option on certain mail servers by turning on the IgnoreSizeErrors feature in IMAPClient
 + added --peek option to prevent marking messages as seen 
 + version 0.7.2

 Tue Jan  5 12:13:53 PST 2010
 + added error message and exit with unknown status when an unrecognized IMAP search criteria is encountered by the --download --search option

 Wed May  5 11:14:51 PDT 2010
 + added mailbox list when mailbox is not found and verbose level 3 is on (-vvv)
 + version 0.7.3

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

