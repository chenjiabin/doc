#!/usr/bin/env python
# Pull data from buildbot 0.8.7p1 json api
# email: support-list@op5.com
# website: http://www.op5.com http://www.op5.org

import json
import sys
import urllib2
import re
from optparse import OptionParser

def abort (msg=False):
	if msg:
		print "UNKNOWN: %s" % msg
	sys.exit(3)

def msg_ok (msg=False):
	if msg:
		print "OK: %s" % msg
	sys.exit(0)

def msg_warning (msg=False):
	if msg:
		print "WARNING: %s" % msg
	sys.exit(1)

def msg_unknown (msg=False):
	if msg:
		print "UNKNOWN: %s" % msg
	sys.exit(3)

def msg_critical (msg=False):
	if msg:
		print "CRITICAL: %s" % msg
	sys.exit(2)

def get_json (url, raw=False):
	try:
		data = urllib2.urlopen(url)
	except urllib2.URLError as e:
		abort("Can't connect to url: %s" % url)
	except:
		abort("Unexpected error:", sys.exc_info()[0])

	decoded = json.loads(data.read())
	if raw:
		return decoded

	for item in decoded:
		try:
			if decoded[item]['error'] == "Not available":
				abort("No decent json output for %s" % item)
		except KeyError:
			continue
	return decoded

def get_jobs (options):
	output = ''
	perfdata = ''
	if options.slave:
		url = "http://%s:%s/json/slaves?select=%s" % (options.host, options.port, options.slave)
	else:
		url = "http://%s:%s/json/slaves" % (options.host, options.port)

	decoded = get_json(url)
	for item in sorted(decoded):
		jobs = (len(decoded[item]['runningBuilds']))
		if jobs < 2:
			output += "%s - %s job, " % (item, jobs)
		else:
			output += "%s - %s jobs, " % (item, jobs)

		perfdata += "%s=%s; " % (item, jobs)

	if not output:
		msg_warning("Can't find matching slave: %s" % options.slave)

	msg_ok("%s|%s" % (output, perfdata))

def get_connection (options):
	output_connected = ''
	output_disconnected = ''
	perfdata = ''
	if options.slave:
		url = "http://%s:%s/json/slaves?select=%s" % (options.host, options.port, options.slave)
	else:
		url = "http://%s:%s/json/slaves" % (options.host, options.port)

	decoded = get_json(url)
	for item in sorted(decoded):
		if decoded[item]['connected']:
			output_connected += "%s: yes, " % item
		else:
			output_disconnected += "%s: no, " % item
		perfdata += "%s=%s; " % (item, int(decoded[item]['connected']))

	msg_ok("Connected: %s%s|%s" % (output_connected, output_disconnected, perfdata))

def get_builder_status (options):
	if options.name:
		builder = options.name.replace(" ", "%20")
		builder = builder.replace("/", "%2F")
		url = "http://%s:%s/json/builders/%s/builds/-1" % (options.host, options.port, builder)
		decoded = get_json(url, raw=True)
		status = ''.join(str(x)+" " for x in decoded['text'])
		start = decoded['times'][0]
		stop = decoded['times'][1]
		elapsed = stop - start
		if re.match("build successful", status):
			msg_ok("Build: #%s on builder: %s|buildtime=%ss" % (decoded['number'], decoded['builderName'], elapsed))
		elif re.match("exception.*", status):
			msg_unknown("%s Build: #%s on builder: %s|buildtime=%ss" % (status[:-1], decoded['number'], decoded['builderName'], elapsed))
		else:
			msg_critical("Build: #%s on builder: %s|buildtime=%ss" % (decoded['number'], decoded['builderName'], elapsed))

usage = "usage: %prog -H HOST -m MODE [-s SLAVE]"
parser = OptionParser(usage=usage)
parser.add_option("-H", "--host", dest="host",
		help="buildbot master to query against")
parser.add_option("-p", "--port", dest="port",
		help="port")
parser.add_option("-s", "--slave", dest="slave",
		help="slave to display count from")
parser.add_option("-m", "--mode", dest="mode",
		help="what mode to run, 'jobs|connection|builder'")
parser.add_option("-n", "--name", dest="name",
		help="name, to be used with 'builder'")
(options, args) = parser.parse_args()

if not options.host or not options.mode:
	parser.print_usage()
	abort()

if not options.port:
	options.port = 8010

if options.mode == "jobs":
	get_jobs(options)
elif options.mode == "connection":
	get_connection(options)
elif options.mode == "builder":
	get_builder_status(options)

parser.print_usage()
abort()



