#!/bin/sh
#
# Nagios JMX plugin.
#

JAVA_CMD=`which java`

if [ -z "$JAVA_CMD" ]; then
	if [ -x "$JAVA_HOME/bin/java" ]; then
		JAVA_CMD=$JAVA_HOME/bin/java
	else
		echo "JMX CRITICAL - java not found."
		exit 2
	fi
fi

DIR=`dirname $0`
"$JAVA_CMD" -jar "$DIR/check_jmx.jar" "$@"
