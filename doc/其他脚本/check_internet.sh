#!/bin/sh
#
# Nagios plugin to check wether Internet is still working or not :)
#
# License: GPL
# Copyright (c) 2007 op5 AB
# Author: Johannes Dagemark <jd@op5.com>
#
# For direct contact with any of the op5 developers send a mail to
# op5-users@lists.op5.com
# Discussions are directed to the mailing list op5-users@op5.com,
# see http://lists.op5.com/mailman/listinfo/op5-users
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

if [ $# -lt 1 ]; then
    echo "no hosts specified"
    exit 3
fi

sites=$@

if [ $# -ge 1 ]; then
    sites="$@"
fi
for host in $sites; do
    /opt/plugins/check_http -H $host -t 5 >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Internet is UP, $host responded"
                exit 0
        fi
done
echo "Internet is Down, none of checked hosts: $sites responded"
exit 2

