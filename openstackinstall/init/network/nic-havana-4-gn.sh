#!/bin/bash
NIC=$1
if [ -n "$NIC" ]; then
IP=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep IPADDR | cut -d "=" -f 2`
NETMASK=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep NETMASK | cut -d "=" -f 2`
GATEWAY=`more /etc/sysconfig/network-scripts/ifcfg-$NIC | grep GATEWAY | cut -d "=" -f 2`

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=none
SLAVE=yes
MASTER=bond0
USERCTL=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE=eth1
ONBOOT=yes
BOOTPROTO=none
SLAVE=yes
MASTER=bond0
USERCTL=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 << EOF
DEVICE=eth2
ONBOOT=yes
BOOTPROTO=none
SLAVE=yes
MASTER=bond1
USERCTL=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth3 << EOF
DEVICE=eth3
ONBOOT=yes
BOOTPROTO=none
SLAVE=yes
MASTER=bond1
USERCTL=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-bond0 << EOF
DEVICE=bond0
BOOTPROTO=none
ONBOOT=yes
USERCTL=no
BRIDGE=br0
BONDING_OPTS="miimon=100 mode=0"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-bond1 << EOF
DEVICE=bond1
BOOTPROTO=none
ONBOOT=yes
USERCTL=no
BRIDGE=br1
BONDING_OPTS="miimon=100 mode=4"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 << EOF
DEVICE=br0
ONBOOT=yes
TYPE=Bridge
BOOTPROTO=none
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br1 << EOF
DEVICE=br1
ONBOOT=yes
BOOTPROTO=none
TYPE=Bridge
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br1:1 << EOF
DEVICE=br1:1
BOOTPROTO=static
ONBOOT=yes
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
TYPE=Bridge
DELAY=0
EOF

echo "alias bond0 bond1 bonding" > /etc/modprobe.d/bonding.conf

service network restart
service network restart

fi

