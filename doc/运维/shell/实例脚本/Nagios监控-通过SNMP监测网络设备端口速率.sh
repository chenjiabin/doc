#!/bin/bash
CALLER=`basename $0` 
#echo $CALLER
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3      
#warn=
#criti=
Usage()
    {
	echo "USAGE: $CALLER [-h] "
	echo "WHERE: -h = help "
	echo "$CALLER -H IP -C community -o OID -w warning -c critical"
	echo "* such as: "
	echo "$CALLER -H 192.168.1.1 -c public -o 1 -w 60 -c 80"
  exit 1
	}
###############if the varible is legal#################################
if [ $# -eq 0 ];then
	echo "no parameters"
	Usage
	exit
fi
for i in $@; do
       #catch the help
	if [ "$i"x = "-h"x ] || [ "$i"x = "--help"x ]; then
		Usage ; exit
	fi
done
if [ $# -ne 10 ]; then
	echo "parameters error"
	echo "try $CALLER --help"
	exit
fi
	while [ $# -gt 0 ]; do
		case $1 in
				#set the variables based on input
				-H)	shift
					if [ $# -ne 0 ]; then
						IP=$1
						IP_NUM=`echo $IP | awk -F. '{i=1;while(i<=NF) {print $i;i++}}'`
						for r in $IP_NUM; do
							if [ $r -lt 0 ] || [ $r -gt 255 ]; then
								echo "please input legal IP address"
								exit
							fi
						done
					else
						Usage
						exit
					fi
					shift
#echo IP=$IP
				;;
				-C)	shift
					if [ $# -ne 0 ]; then
						community=$1
#echo community=$community
					else
						Usage
						exit
					fi
					shift
				;;
				-o)	shift
					if [ $# -ne 0 ]; then
						OID=$1
					else
						Usage
						exit
					fi
#echo OID=$OID
					shift
				;;
				-w)	shift
					if [ $# -ne 0 ]; then
						warn=$1
#echo warn=$warn						
					else
						Usage
						exit
					fi
					shift
				;;
				-c)	shift
					if [ $# -ne 0 ]; then
						criti=$1
#echo criti=$criti
					else
						Usage
						exit
					fi
					shift
				;;
				*)		echo "Unknown option"
						echo "try $CALLER --help"
				;;
		esac
	done
if [ $warn -gt $criti ]; then 
	echo "The warning must less than CRITICAL"
	exit
fi
#######################################################################################################
[ -d /tmp/traffic/$IP ];[ $? -ne 0 ] && mkdir -p /tmp/traffic/$IP

################################test port status
#snmpwalk -v 2c -c $community $IP > /tmp/traffic/$IP/snmpinfo.tmp
#line=`cat /tmp/traffic/$IP/snmpinfo.tmp | cut -d " " -f1 | grep -n "\.$OID"$`
#line_num=cat $line | awk -F ':' '{print $1}'
#port_status=`snmpwalk -v 2c -c $community $IP ifOperStatus | awk 'NR==$line_num {print $4}' | cut -d "(" -f1`

#cat /tmp/traffic/$IP/snmpinfo.tmp | cut -d " " -f1 | grep  "\.$OID"$
#if [ $? -ne 0 ];then
#	echo "Sorry,the OID is not exist"
#	echo"Usage:snmpwalk -v 2c -c $community $IP ifOperStatus"
#elif [ $port_status = down ];then
#	echo "sorry the port status is down"
#	exit
#fi
#############################################################################################################
#if it the first time runing or not
[ -e /tmp/traffic/$IP/Ptraffic$OID.tmp ]
	if [ $? -ne 0 ]; then
		echo -n `snmpwalk -v 2c -c $community $IP ifInOctets.$OID | cut -d " " -f4`  >   /tmp/traffic/$IP/Ptraffic$OID.tmp
		echo -n " " >> /tmp/traffic/$IP/Ptraffic$OID.tmp
		echo -n `snmpwalk -v 2c -c $community $IP ifOutOctets.$OID | cut -d " " -f4`  >>   /tmp/traffic/$IP/Ptraffic$OID.tmp
		echo -n " " >> /tmp/traffic/$IP/Ptraffic$OID.tmp
		echo `date +%s` >> /tmp/traffic/$IP/Ptraffic$OID.tmp
		exit
	fi

s1=`awk '{print $1}' /tmp/traffic/$IP/Ptraffic$OID.tmp`
s3=`awk '{print $2}' /tmp/traffic/$IP/Ptraffic$OID.tmp`
s5=`awk '{print $3}' /tmp/traffic/$IP/Ptraffic$OID.tmp`
echo -n `snmpwalk -v 2c -c $community $IP ifInOctets.$OID | cut -d " " -f4`  >   /tmp/traffic/$IP/Ptraffic$OID.tmp
echo -n " " >> /tmp/traffic/$IP/Ptraffic$OID.tmp
echo -n `snmpwalk -v 2c -c $community $IP ifOutOctets.$OID | cut -d " " -f4`  >>   /tmp/traffic/$IP/Ptraffic$OID.tmp
echo -n " " >> /tmp/traffic/$IP/Ptraffic$OID.tmp
echo `date +%s` >> /tmp/traffic/$IP/Ptraffic$OID.tmp
s2=`awk '{print $1}' /tmp/traffic/$IP/Ptraffic$OID.tmp`
s4=`awk '{print $2}' /tmp/traffic/$IP/Ptraffic$OID.tmp`
s6=`awk '{print $3}' /tmp/traffic/$IP/Ptraffic$OID.tmp`
time=`echo "scale=3;$s6 - $s5" | bc`
in=`echo "scale=3;ii=($s2 - $s1)/1024/$time;if(ii < 1 && ii > 0) print 0;print ii;" | bc`
out=`echo "scale=3;oo=($s4 - $s3)/1024/$time;if(oo < 1 && oo > 0) print 0;print oo;" | bc`
total=`echo "( $in + $out )*10/10" | bc`
#echo $total $criti
if [ $total -ge $criti ];then
        echo "Traffic CRITICAL: Total rate:$total Kbps | Input=$in;$warn;$crit;0;20480;;Output=$out;$warn;$criti;0;20480;"
		exit $STATE_CRITICAL
elif [ $total -ge $warn ];then
        echo "Traffic WARNING: Total rate:$total Kbps | Input=$in;$warn;$criti;0;20480;;Output=$out;$warn;$criti;0;20480;"
		exit $STATE_WARNING
elif [ $warn -ge $total ];then
        echo "Traffic OK: Total rate:$total Kbps | Input=$in;$warn;$criti;0;20480;;Output=$out;$warn;$criti;0;20480;"
		exit $STATE_OK
else
        echo  "Traffic CRITICAL: param criti"
		exit $STATE_UNKNOWN
fi

#echo $total


