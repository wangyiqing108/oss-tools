#!/bin/sh
#****************************************************************#
# ScriptName: PCI secure
# version 1.0.1
# Author:
# Create Date: 2016-05-16
# Modify Author: yangtong1@le.com
# Modify Date: 2016-05-16 14:00
# Function: letv pci secure init
#***************************************************************#

USERS="liangyanghe masen wangxiaodong3 cuiyan1 zengjia ganlubing yangtong1 zhangkai8 liuzhaoming"
#stty
stty erase ^H

__detect_color_support() {
    if [ $? -eq 0 ]; then
        RC="\033[1;31m"
        GC="\033[1;32m"
        BC="\033[1;34m"
        YC="\033[1;33m"
        EC="\033[0m"
    else
        RC=""
        GC=""
        BC=""
        YC=""
        EC=""
    fi
}
__detect_color_support

__detect_result() {
	if [ $? -eq 0 ]; then 
		echo -e "${GC}OK${EC}"
		echo ""
	else
		echo -e "${RC}FALSE${EC}"
		echo ""
	fi
}

# SSH配置
clear;echo -en "${BC}SSH root is disabled...	${EC}";sleep 1
#sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/#Protocol 2,1/Protocol 2/g' /etc/ssh/sshd_config
__detect_result

# 编码设置
echo -en "${BC}LANG is en_US.UTF8...	${EC}";sleep 1
sed -i 's/LANG=.*/LANG="en_US.UTF-8"/g' /etc/sysconfig/i18n 
__detect_result

# 租户创建
useradd ledev
echo -en "${BC}Create Users...    ${EC}";sleep 1
if [ $(grep -c "%ledev" /etc/sudoers) == 0 ]; then
{
    echo "%ledev     ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
}
fi
for users in $USERS;do
  getent passwd $users || useradd -g ledev $users
  #mkdir /home/$users/.ssh/ -p
  #chmod 700 /home/$users/.ssh/
  #touch /home/$users/.ssh/authorized_keys
  #chmod 600 /home/$users/.ssh/authorized_keys
  #chown $users.$users  /home/$users/.ssh -R
done
# 服务账户
useradd -s /sbin/nologin ledev
# 删除账户
userdel lp
userdel sync
userdel shutdown
userdel halt
userdel uucp
userdel operator
userdel games
userdel gopher
__detect_result

# 安全配置
clear;echo -en "${BC}Linux secure config...    ${EC}";sleep 1
#sed -i 's/PASS_MAX_DAYS	99999/PASS_MAX_DAYS   90/g' /etc/login.defs
#sed -i 's/PASS_MIN_DAYS	0/PASS_MIN_DAYS   1/g' /etc/login.defs
sed -i 's/PASS_MIN_LEN	5/PASS_MIN_LEN    7/g' /etc/login.defs
sed -i 's/PASS_WARN_AGE	7/PASS_WARN_AGE   7/g' /etc/login.defs
sed -i 's/password    requisite     pam_cracklib.so try_first_pass retry=3 type=/password    requisite     pam_cracklib.so retry=3 minlen=8 lcredit=-1 ucreadit=-1 ocredit=-1/g' /etc/pam.d/system-auth
sed -i '/auth        required      pam_tally2.so/d' /etc/pam.d/system-auth
echo 'auth        required      pam_tally2.so deny=3 unlock_time=1800' >> /etc/pam.d/system-auth
rm -fr /etc/hosts.equiv
rm -fr /etc/xinetd.d/rsh
rm -fr /etc/xinetd.d/rlogin
rm -f /etc/security/console.apps/reboot
rm -f /etc/security/console.apps/halt
rm -f /etc/security/console.apps/shutdown
rm -f /etc/security/console.apps/poweroff
__detect_result
