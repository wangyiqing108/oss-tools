#!/bin/bash
NIC=$1
if [ -n "$NIC" ]; then
IP=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep IPADDR | cut -d "=" -f 2`
NETMASK=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep NETMASK | cut -d "=" -f 2`
GATEWAY=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep GATEWAY | cut -d "=" -f 2`

IP_1=`more /etc/sysconfig/network-scripts/ifcfg-eth1 | grep IPADDR | cut -d "=" -f 2`
NETMASK_1=`more /etc/sysconfig/network-scripts/ifcfg-eth1 | grep NETMASK | cut -d "=" -f 2`
GATEWAY_1=`more /etc/sysconfig/network-scripts/ifcfg-eth1 | grep GATEWAY | cut -d "=" -f 2`

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
ONBOOT=yes
BRIDGE=br0
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE=eth1
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 << EOF
DEVICE=br0
BOOTPROTO=static
ONBOOT=yes
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
TYPE=Bridge
DELAY=0
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0:1 << EOF
DEVICE=br0:1
BOOTPROTO=static
ONBOOT=yes
TYPE=Bridge
IPADDR=$IP_1
NETMASK=$NETMASK_1
DELAY=0
EOF

cat > /etc/sysconfig/network-scripts/route-br0:1  << EOF
10.0.0.0/8 via 10.120.15.1
EOF

service network restart
service network restart

echo "please configration private at br0:1"
echo "please add private route"
echo 'format example:"10.0.0.0/8 via private-gw" for br0'
fi