#!/bin/bash
#yum -y install dmidecode
 
SYSTEM=`cat /etc/issue | head -1`
SYSTEM_Kernel=`uname -a|awk '{print $3}'`
CPU_Version=`awk -F: '/model name/ {print $2}' /proc/cpuinfo |head -1`
Physical_CPU_Number=`cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l`
Processor_CPU_Number=`grep "processor" /proc/cpuinfo |wc -l`
MemTotal=`awk -F"[: ]+" '/MemTotal/ {print $2}' /proc/meminfo `
MemFree=`awk -F"[: ]+" '/MemFree/ {print $2}' /proc/meminfo`
MemUse=$(($MemTotal-$MemFree))
NetworkCard=`/sbin/ifconfig|cut -c1-10|sort |uniq -u`
 
printf '%4s  ----System versions---- \n'
echo $SYSTEM
echo $SYSTEM_Kernel
printf ' \n'
 
 
 
printf '%4s  ----CPU Information---- \n'
echo "CPU_Version: " $CPU_Version
echo "Physical_CPU_Number: "$Physical_CPU_Number
echo "Processor_CPU_Number: "$Processor_CPU_Number
printf ' \n'
 
 
printf '%4s  ----Mem Information---- \n'
echo "MemTotal: $MemTotal kB"
echo "MemFree:  $MemFree  kB"
echo "MemUse:   $((($MemUse*100)/$MemTotal))%"
printf ' \n'
 
printf '%4s  ----Hard disk Information---- \n'
df -h
printf ' \n'
 
printf '%4s  ----Network Information---- \n'
for i in $NetworkCard;do
    IP=`/sbin/ifconfig $i |awk -F"[: ]+" '/inet addr/{print $4}'`
    echo "$i: $IP"
done
 
 
printf ' \n'
printf '%4s  ----server type---- \n'
dmidecode | grep "Product Name"
printf ' \n'
