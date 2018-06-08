#!/bin/bash
IP=`ifconfig br1:1 | grep "inet addr" | awk 'NR==1 {print $2}' | cut -d ":" -f 2`
sed -i "s/10.120.7.13/$IP/g" /etc/nova/nova.conf

mkdir /letv/openstack/nova/instances -p
chown nova.nova /letv/openstack/nova -R
service iptables stop > /dev/null
service ip6tables stop > /dev/null

chkconfig  iptables off
chkconfig  ip6tables off

sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/" /etc/sysctl.conf > /dev/null
sed -i "11s/timeout=5/timeout=0/" /boot/grub/grub.conf

service libvirtd restart
chkconfig libvirtd on

virsh net-destroy default

virsh net-undefine default
service messagebus start
chkconfig messagebus on

service openstack-nova-compute restart
service openstack-nova-network restart

chkconfig openstack-nova-compute on
chkconfig openstack-nova-network on
