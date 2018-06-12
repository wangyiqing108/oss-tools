#!/bin/bash
#wget -P /root/.ssh/ http://115.182.93.170:8080/Tools/ssh_key/hosts.key
wget -P /root/.ssh/ http://115.182.93.170:8080/Tools/ssh_key/hosts.key
cat /root/.ssh/hosts.key >> /root/.ssh/authorized_keys
rm -rf /root/.ssh/hosts.key
echo Myiaas.chensh.net | passwd --stdin root
cat >> /etc/hosts.allow << EOF
sshd:10.104.28.116
sshd:10.204.
sshd:10.182.
sshd:117.121.58.68
sshd:10.58.102.210
sshd:10.154.
sshd:10.120.
sshd:10.121.
sshd:10.176.
sshd:10.135.
sshd:10.142.
sshd:10.11.140.
sshd:10.11.143.
sshd:10.104.
sshd:10.100.150.
sshd:10.130.150.
sshd:10.180.150.
sshd:123.126.33.253
EOF
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak
mv /etc/yum.repos.d/letv-pkgs.repo /etc/yum.repos.d/letv-pkgs.repo_bak

rpm -e virt-top-1.0.4-3.15.el6.x86_64
rpm -e libvirt-client-0.10.2-46.el6_6.3.x86_64
#rpm -e letv-rdo-release-icehouse-6.0.noarch
#rpm -ivh http://115.182.93.170/repo/letv-rdo-release-icehouse-6.0.noarch.rpm
#rpm -ivh http://115.182.93.170/repo/letv-rdo-release-havana-10.0.noarch.rpm
rpm -ivh http://115.182.93.170/repo/letv-rdo-release-icehouse-6.0.noarch.rpm

