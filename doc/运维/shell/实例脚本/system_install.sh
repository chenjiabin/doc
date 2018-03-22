#!/bin/bash
##############################################system-check############################################
system_ch=`cat /etc/issue |sed -n '1p'`    									#system versions
system_num=`cat /etc/issue |grep -o [1-9]\.[1-9]|awk -F "." '{print $1}'`					#system number
service(){
echo "###########################################service status##########################################################"
for name in NetworkManager avahi-daemon avahi-dhsconfd bluetooth capi dnsmasq dund hidd hplip ip6tables iptables isdn ntpd mcstrans pcscd restorecond sendmail setroubleshoot 
do
	if [ -f "/etc/init.d/$name" ]
	then
		chk_ch=`chkconfig --list $name | awk '{print$5}' | awk -F ":" '{print$2}'` >/dev/null 2>&1            #kaiji qidong list
		if [ $chk_ch == 关闭 ] || [ $chk_ch == off ]
		then
			echo "--------------------------------------------------------"
			echo "service $name is not startup program"
		else
			echo "--------------------------------------------------------"
			echo "service $name is startup program,please wait a moment..."
			chkconfig $name off >/dev/null 2>&1
			/sbin/service $name stop >/dev/null 2>&1
			echo "service $name close the startup"
		fi
	fi
done
}

selinux(){
echo "###########################################selinux################################################################"

selinux_ch=`/usr/sbin/sestatus -v | grep status |awk '{print$3}'`                       #selinux status
if [ $selinux_ch == disabled ]
then
	echo "selinux is closed"
else
	echo "selinux is running,please wait a moment..."
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	echo "selinux is already closed"
fi
}

network(){
echo "#####################################network#######################################################################"
network_ch=`ifconfig bond0 2>&1 |egrep -o '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}'|sed -n '1p'`		#bond0ip
netcard_name=`ls /etc/sysconfig/network-scripts/ |grep ifcfg |awk -F "-" '{print$2}' |tr "\n" "/"`
stty erase '^H' 
read -p "Please enter the standard configuration of IP：" ip
read -p "Please enter the standard subnet mask：" netmask
read -p "Please enter the standard gateway:" gateway
read -p "Please select the first activate the network card($netcard_name):" netcard1
read -p "Please select the second activation network card（$netcard_name）:" netcard2
if [[ $network_ch == $ip ]]
then
	echo "Network has been configured，IP:$network_ch"
else
	echo "Network is not configured,please wait a moment..."
	net_mac1=`cat /etc/sysconfig/network-scripts/ifcfg-$netcard1|grep HWADDR|awk -F "=" '{print$2}'`                #network card1 mac
        net_mac2=`cat /etc/sysconfig/network-scripts/ifcfg-$netcard2|grep HWADDR|awk -F "=" '{print$2}'`                #network card2 mac
        echo > /etc/sysconfig/network-scripts/ifcfg-$netcard1
        cat >> /etc/sysconfig/network-scripts/ifcfg-$netcard1 <<EOF-netcard1
DEVICE=$netcard1
HWADDR=$net_mac1
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
MASTER=bond0
USERCTL=no
SLAVE=yes
EOF-netcard1

        echo > /etc/sysconfig/network-scripts/ifcfg-$netcard2
        cat >> /etc/sysconfig/network-scripts/ifcfg-$netcard2 <<EOF-netcard2
DEVICE=$netcard2
HWADDR=$net_mac2
TYPE=Ethernet   
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
MASTER=bond0
USERCTL=no
SLAVE=yes
EOF-netcard2

	case $system_num in
	6)
		echo > /etc/sysconfig/network-scripts/ifcfg-bond0
		cat >> /etc/sysconfig/network-scripts/ifcfg-bond0 <<EOF-network
DEVICE=bond0
ONBOOT=yes
BOOTPROTO=static
IPADDR=$ip
NETMASK=$netmask
GATEWAY=$gateway
BONDING_OPTS="miimon=100 mode=1"
EOF-network
	;;
	5)
		echo > /etc/sysconfig/network-scripts/ifcfg-bond0
                cat >> /etc/sysconfig/network-scripts/ifcfg-bond0 <<EOF-network5
DEVICE=bond0
ONBOOT=yes
BOOTPROTO=static
IPADDR=$ip
NETMASK=$netmask
EOF-network5
		sed -i '/^GATEWAY/s/^/#/' /etc/sysconfig/network
		echo "GATEWAY=$gateway" >> /etc/sysconfig/network

		sed -i '/^install bond0/s/^/#/' /etc/modprobe.conf
		sed -i '/^options bonding/s/^/#/' /etc/modprobe.conf
		sed -i '/^alias bond0/s/^/#/' /etc/modprobe.conf
		cat >> /etc/modprobe.conf <<EOF-modp
install bond0 /sbin/modprobe -a eth0 eth1 && /sbin/modprobe bonding
options bonding mode=1 miimon=100
alias bond0 bonding
EOF-modp
	;;
	esac
	/sbin/service network restart >/dev/null 2>&1
	echo "The network configuration has been completed"
	ifconfig
	cat /proc/net/bonding/bond0
fi

}
profile(){
echo "###########################################timestamp##############################################################"
profile_ch=`cat /etc/profile | grep HISTTIMEFORMAT |awk -F "=" '{print$2}'`                          #timestamp check
if [[ $profile_ch == "\"%F %T \`whoami\`\"" ]]
then
	echo "The system has been added timestamp"
else
	echo "The system not add the timestamp,please wait a moment..."
	echo 'export HISTTIMEFORMAT="%F %T `whoami`"' >>/etc/profile
	echo "System configuration has been completed of timestamp"
fi

}

ntp(){
echo "###########################################ntp###################################################################"
ntp_ch=`crontab -l |grep ntpdate`             #ntpcheck
ntp_ip1=`crontab -l |grep ntpdate |egrep -o '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}'|sed -n '1p'`                         #ntp firstIP
ntp_ip2=`crontab -l |grep ntpdate |egrep -o '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}'|sed -n '2p'`                         #ntp secondIP
if [[ $ntp_ch ]]
then
	echo "service ntp configuration has been completed,IP1:$ntp_ip1  IP2:$ntp_ip2"
else
	echo "service ntp is not configured,please wait a moment..."
	echo "* */1 * * * /usr/sbin/ntpdate 10.142.130.62;/usr/sbin/ntpdate 10.142.130.69;/usr/sbin/hwclock -w" >>/var/spool/cron/root  
	ntpdate 10.142.130.62  >/dev/null 2>&1
	echo "service ntp configuration has been completed"
fi
}

autofind(){
echo "########################################autofind##################################################################"
user_ch=`cat /etc/passwd |grep unionmon|awk -F ":" '{print$1}'`					#user unionmon check
if [[ $user_ch == unionmon ]]
then
	echo "User unionmon already exist"
else
	echo "user unionmon is creating,please wait a moment..."
	useradd  -d /home/unionmon -s /bin/bash unionmon >/dev/null 2>&1
	echo 'R9%slD1(aTz^mNY' | passwd --stdin unionmon >/dev/null 2>&1
	echo "user unionmon has been created"
fi

i=0
req_ch=`cat /etc/sudoers |grep ^Defaults |grep requiretty`				#sudoers requiretty check
if [[ $req_ch ]]
then
	if [[ ! /etc/sudoers.bak ]]
	then
		/bin/cp /etc/sudoers{,.bak}
	fi
	sed -i 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers
else
	let i++
fi

union_ch=`cat /etc/sudoers |grep unionmon`						#unionmon check
if [[ $union_ch ]]
then
	let i++
else
	cat >> /etc/sudoers << EOF-uni
unionmon ALL=(root) NOPASSWD: /usr/sbin/lsof,/usr/sbin/dmidecode,/usr/sbin/lvdisplay,/usr/sbin/vgdisplay,/usr/sbin/pvdisplay,/bin/ls,/usr/bin/cksum,/bin/dd,/sbin/mii-tool,/sbin/fdisk
EOF-uni
fi

unipath_ch=`cat ~unionmon/.bash_profile|grep "export PATH=" |awk -F "=" '{print$2}'`		#unionmon path check
if [[ $unipath_ch == "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:\${PATH}" ]]
then
	let i++
else
	echo 'export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:${PATH}' >> ~unionmon/.bash_profile
fi

if [[ $i -lt 3 ]]
then
	echo "service autofind is not configured,please wait a moment..."
	echo "service autofind configuration has been completed"
else
	echo "service autofind configuration has been completed"
fi
}

file_m(){
echo "####################################################file_max########################################################"
soft_ch=`cat /etc/security/limits.conf|grep ^* |grep soft |grep nofile|awk '{print$4}'`			#soft check
hard_ch=`cat /etc/security/limits.conf|grep ^* |grep hard |grep nofile|awk '{print$4}'			#hard check`
if [[ $soft_ch == 65535 ]] && [[ $hard_ch == 65535 ]]
then
	echo "The max number of open-file is 65535"
else
	echo "The max number of open-file is not configuration,please wait a moment..."
	sed -i '/^*/s/^/#/' /etc/security/limits.conf	                         	#*kaitou  zhushi
	cat >> /etc/security/limits.conf <<EOF-limit                            	#add peizhi
*    soft   nofile   65535
*    hard   nofile   65535
EOF-limit
	echo "file_max is ok"
fi

}

snmp(){
echo "###################################################snmp#############################################################"
if [ -f /etc/init.d/snmp ]
then
	snmp_ch=`cat /etc/snmp/snmpd.conf  |grep ^com2sec|grep notConfigUser|awk '{print$4}'`
	if [[ $snmp_ch == ECS_Unicom ]]
	then
		echo "service snmp configuration has been completed"
	else
		echo "service snmp is not configured please wait a moment..."
		sed -i 's/com2sec notConfigUser  default       public/com2sec notConfigUser  default      ECS_Unicom/' /etc/snmp/snmp.conf
	fi
else
	echo "service snmp is not exist"
fi

}
shuchu(){
echo "###############################################################################################################"
echo "system versions:$system_ch"
echo "1 check and configure the network"
echo "2 check and configure the selinux"
echo "3 check and configure the ntp"
echo "4 check and configure the chkconfig "
echo "5 check and configure all"
echo "6 check and configure (not contain network)"
echo "7 exit"
stty erase '^H'
read -p "Plese choose the num of your need：" choose
case $choose in
1)
        network
        chushu
        ;;
2)
        selinux
        shuchu
        ;;
3)
        ntp
        shuchu
        ;;
4)
        service
        shuchu
        ;;
5)
        service
        selinux
	network
        profile
        ntp
        autofind
        file_m
        snmp
        shuchu
        ;;
6)
        service
        selinux
        profile
        ntp
        autofind
        file_m
        snmp
        shuchu
        ;;
7)
        exit 0
        ;;
esac

}

shuchu
