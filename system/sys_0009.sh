#!/bin/bash
# hpsa driver
# check syslog
SYSLOG=`more /var/log/messages | grep hpsa | grep "out of memory" | head -n1`
if [ -n "$SYSLOG" ]; then
echo "#****************************"
echo "# Check:"
echo "Bug ------> $SYSLOG"
echo "Kernel version -------> `uname -r`"

HPSA_OLD=`rpm -qa | grep kmod-hpsa-3.4.2`
	if [ -n "$HPSA_OLD" ]; then
		HPSA_NUM=`rpm -qa | grep kmod-hpsa | wc -l`
		if [ "$HPSA_NUM" == "1" ]; then
			if [ -n "`uname -r | grep 279`" ]; then
				rpm -ivh http://openstack.oss.letv.cn:8080/Tools/hpsa-tools/kmod-hpsa-3.4.12-110.rhel6u3.x86_64.rpm --force
				echo "kmod-hpsa update ok,please reboot~!"
			elif [ -n "`uname -r | grep 431`" ]; then
				rpm -ivh http://openstack.oss.letv.cn:8080/Tools/hpsa-tools/kmod-hpsa-3.4.12-110.rhel6u5.x86_64.rpm --force
				echo "kmod-hpsa update ok,please reboot~!"
			elif [ -n "`uname -r | grep 504`" ]; then
				rpm -ivh http://openstack.oss.letv.cn:8080/Tools/hpsa-tools/kmod-hpsa-3.4.12-110.rhel6u6.x86_64.rpm --force
				echo "kmod-hpsa update ok,please reboot~!"
			fi
		else
			echo "#****************************"
			echo "# Verify:"
			echo "kmod-hpsa have update: `rpm -qa | grep kmod-hpsa | head -n1`"
		fi
	fi
fi
