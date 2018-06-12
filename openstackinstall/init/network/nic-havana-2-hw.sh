#!/bin/bash
NIC=$1
if [ -n "$NIC" ]; then
IP=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep IPADDR | cut -d "=" -f 2`
NETMASK=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep NETMASK | cut -d "=" -f 2`
GATEWAY=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep GATEWAY | cut -d "=" -f 2`

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0 
ONBOOT=yes
BRIDGE=br0
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE=eth1 
ONBOOT=yes
BRIDGE=br1
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 << EOF
DEVICE=br0
ONBOOT=yes
BOOTPROTO=none
TYPE=Bridge
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br1 << EOF
DEVICE=br1
ONBOOT=yes
BOOTPROTO=none
TYPE=Bridge
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0:1 << EOF
DEVICE=br0:1
BOOTPROTO=static
ONBOOT=yes
TYPE=Bridge
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
DELAY=0
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br1:1 << EOF
DEVICE=br1:1
BOOTPROTO=static
ONBOOT=yes
TYPE=Bridge
IPADDR=172.16.10.99
NETMASK=255.255.0.0
DELAY=0
EOF

service network restart
service network restart
echo "please configration private at br1:1"
echo "please add private route"
echo 'format example:"10.0.0.0/8 via private-gw" for br1'

fi

