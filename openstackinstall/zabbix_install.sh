#!/bin/bash

#--------------------------------------------------------------|
#   @Program    : Zabbix_install.sh                            |  
#   @Version    : 1.0                                          |
#   @Company    : Letv					                       |
#   @Dep.       : Noc				                           |
#   @Writer     : kevin   <huangsicong@letv.com>       	       |
#   @Team Leader: zhuchen <zhuchen@letv.com>   		           |
#   @Date       : 2014-11-14                                   |
#--------------------------------------------------------------|

hostname=`hostname`
uname=`uname`
release=`uname -a`

soft_pool="http://115.182.93.59:8080/zabbix/"
soft_pool_bak="http://115.182.51.13:8080/zabbix/"
zabbix_dir="/usr/local/zabbix/"
zabbix_conf_script_src="conf_script_latest.tar.gz"
zabbix_add_user_script="add_zabbix_user.sh"
zabbix_check_zabbix_script="check_zabbix.sh"
host_temp="host.temp"
zabbix_src=""

#脚本日志路径
time=`date +'%Y-%m'`
log="/var/log/zabbix_install-$time"

function get_zabbix_src_verison()
{
	echo "starting get zabbix agent version..." >>$log
	kernel_version=`uname  -a  | awk ' { print $3 } ' | awk -F'-' ' { print $1 } ' | tr -d '.' `
	#2623 means the keverl version is 2.6.23
	if [ `echo $release|grep -i "x86_64"|wc -l` -eq 1 ]
	then 
		if [ $kernel_version  -ge 2623 ]
		then  
			zabbix_src="zabbix_agents_2.2.7.linux2_6_23.amd64.tar.gz"
		else
			zabbix_src="zabbix_agents_2.2.7.linux2_4.i386.tar.gz"
		fi
	else
		if [ $kernel_version  -ge 2623 ]
		then  
			zabbix_src="zabbix_agents_2.2.7.linux2_6_23.i386.tar.gz"
		else
			zabbix_src="zabbix_agents_2.2.7.linux2_4.i386.tar.gz"
		fi
	fi
		
	#check result
	if [ -z $zabbix_src ] 
	then 
		echo "can not get zabbix agent version failed,exit!" >>$log
		exit
	fi
}

function add_sudo () 
{
	echo "staring add sudo permission" >>$log
	if [ "$uname" = "linux" ] || [ "$uname" = "Linux" ]
	then
		if [ -f /etc/sudoers ]
		then
			t=`grep -c '/usr/bin/iotop' /etc/sudoers` 
			if [ $t -eq 0 ]
			then
				echo "add sudo permission" >>$log
				sed -i "s/^Defaults.*requiretty/#Defaults    requiretty/" /etc/sudoers 
				sed -i '/zabbix/d' /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /sbin/ethtool" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /bin/cat" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/sbin/mtr" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /bin/ping" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/sbin/megacli64" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/sbin/hpacucli" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/bin/lsiutil" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/bin/ipmitool" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /sbin/ipvsadm" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/sbin/hwconfig" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/sbin/dmidecode" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/sbin/ss" >> /etc/sudoers
				echo "zabbix          ALL=NOPASSWD: /usr/bin/tail" >> /etc/sudoers
				echo "zabbix	      ALL=NOPASSWD: /usr/bin/iotop" >> /etc/sudoers

				if [ -z "`cat /etc/hosts | grep $hostname | grep 127.0.0.1`" ]
				then
					sed -i "s/^127.0.0.1.*/& $hostname/" /etc/hosts
				fi

			else
				echo "add sudo permission already exists,skip" >>$log
			fi

		else
			echo "sudoers file not found" >>$log
			exit
		fi

		#创建ethtool的软链接
		if [ -s /usr/sbin/ethtool -a ! -s /sbin/ethtool ]
		then
			ln -s /usr/sbin/ethtool /sbin/ethtool
		fi
	fi
}

function wget_lastest_zabbix()
{
	cd  $zabbix_dir
	echo "starting downloading zabbix packages and zabbix conf_script packages..." >>$log
	if [ `curl -Is --connect-timeout 3 --max-time 3 "${soft_pool}$agents{zabbix_src}"|grep -c 'HTTP/1.1 200 OK'` -eq 1 ]
 	then
		wget -T 60 -O ${zabbix_src} ${soft_pool}zabbix_agents/${zabbix_src}  >/dev/null 2>&1
		wget -T 60 -O ${zabbix_conf_script_src} ${soft_pool}${zabbix_conf_script_src}  >/dev/null 2>&1
		wget -T 60 -O ${zabbix_add_user_script} ${soft_pool}${zabbix_add_user_script}  >/dev/null 2>&1
		wget -T 60 -O ${zabbix_check_zabbix_script} ${soft_pool}${zabbix_check_zabbix_script}  >/dev/null 2>&1
		wget -T 60 -O ${host_temp} ${soft_pool}${host_temp}  >/dev/null 2>&1
		echo "downloading zabbix packages and zabbix conf_script packages and zabbix_add_user_script and zabbix_check_zabbix_script from ${soft_pool}..." >>$log
	else
		wget -T 60 -O ${zabbix_src} ${soft_pool_bak}zabbix_agents/${zabbix_src}  >/dev/null 2>&1
		wget -T 60 -O ${zabbix_conf_script_src} ${soft_pool_bak}${zabbix_conf_script_src}  >/dev/null 2>&1
		wget -T 60 -O ${zabbix_add_user_script} ${soft_pool_bak}${zabbix_add_user_script}  >/dev/null 2>&1
		wget -T 60 -O ${zabbix_check_zabbix_script} ${soft_pool_bak}${zabbix_check_zabbix_script}  >/dev/null 2>&1
		wget -T 60 -O conf/${host_temp} ${soft_pool_bak}${host_temp}  >/dev/null 2>&1
		echo "downloading zabbix packages and zabbix conf_script packages and zabbix_add_user_script and zabbix_check_zabbix_script from ${soft_pool_bak}..." >>$log
	fi

	#check result
	if [ ! -f $zabbix_dir$zabbix_src ]
	then
		echo "downing $zabbix_src failed,exit!" >>$log
		exit
	elif [ ! -f $zabbix_dir$zabbix_conf_script_src ]
	then 
		echo "downing $zabbix_conf_script_src failed,exit!" >>$log
		exit
	elif [ ! -f $zabbix_dir$zabbix_add_user_script ]
	then 
		echo "downing $zabbix_add_user_script failed,exit!" >>$log
		exit
	elif [ ! -f $zabbix_dir$zabbix_check_zabbix_script ]
	then
		echo "downing $zabbix_check_zabbix_script failed,exit!" >>$log
        exit
	else
		echo "downing all success!" >>$log
	fi

}

function unzip()
{
	cd  $zabbix_dir
	echo "staring unzip packages..." >>$log

	tar xfz $zabbix_src

	if [ $? -gt 0 ]
	then 
		echo "unzip  $zabbix_src failed,exit!" >>$log
		exit
	fi

	tar xfz $zabbix_conf_script_src

	if [ $? -gt 0 ]
	then 
		echo "unzip $zabbix_conf_script_src failed,exit!" >>$log
		exit
	fi

	#赋权
	chown -R zabbix.zabbix /usr/local/zabbix
	#添加到系统自启动脚本中
	sed -i '/zabbix_agentd/d' /etc/rc.d/rc.local
	t=`grep -c 'zabbix_agentd.conf start' /etc/rc.d/rc.local` 
	if [ $t -eq 0 ]
	then
		echo "add to rc.local" >>$log
		echo "/usr/local/zabbix/sbin/zabbix_agentd -c /usr/local/zabbix/conf/zabbix_agentd.conf start" >> /etc/rc.d/rc.local
	else
		echo "rc.local alreay exists,skip" >>$log
	fi
}

function add_zabbix_crontab()
{
	echo "add crontab for zabbix..." >>$log
	#添加计划任务
    crontab_file="/var/spool/cron/zabbix"
    if [ -f  $crontab_file ]
    then
        t=`grep -c 'zabbix_agentd.log' "$crontab_file"` 
        if [ $t -eq 0 ]
        then
            cat ${zabbix_dir}crond.zabbix >>$crontab_file
        else
            echo "crontab for zabbix alreay exists,skip" >>$log
        fi
    else
            echo "crontab file not exit,create file and add crontab to zabbix" >>$log
            cat ${zabbix_dir}crond.zabbix >>$crontab_file
	fi
}

function add_zabbix_user()
{
    chmod u+x $zabbix_dir$zabbix_add_user_script
    t=`grep -c  'zabbix' /etc/passwd`
    if [ $t -eq 0 ]
    then
	#add user
	$zabbix_dir$zabbix_add_user_script
	if [ $? -eq 0  ]
	then
	    echo "excute zabbix_add_user_script success" >>$log
	    rm -rf $zabbix_dir$zabbix_add_user_script
	else
	    echo "excute zabbix_add_user_script failed!" >>$log
	    exit
	fi

    else
        echo "user already exists!for zabbix alreay exists,skip" >>$log
    fi

    }

A=`pwd`

echo "" >$log
#获取正确的zabbix agent版本
get_zabbix_src_verison

mkdir $zabbix_dir
chown zabbix.zabbix $zabbix_dir
#下载、创建用户、解压、添加计划任务
wget_lastest_zabbix
#创建zabbix用户
add_zabbix_user
unzip
add_zabbix_crontab

#添加sudo 权限
add_sudo

#重启zabbix agentd
killall -9 zabbix_agentd
chmod a+x /usr/local/zabbix/check_zabbix.sh
/bin/bash /usr/local/zabbix/check_zabbix.sh
#删除本脚本
rm -f $A/$0
