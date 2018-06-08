#!/bin/bash
NIC_DEFAULT=`ip ro | grep default | awk '{print $5}'`
NIC_NEI=eth1

function nic_ixgbe_change() {
    if [ ! -f "/tmp/hwconfig" ];then
        hwconfig > /tmp/hwconfig
    fi

    NODE_TYPE=`cat /etc/issue|head -n1|cut -d " " -f3`
    NUM_NIC=`cat /tmp/hwconfig|grep -E  "eth0|eth1|eth2|eth3"|wc -l`
    NUM_IXGBE_NIC=`cat /tmp/hwconfig|grep -E  "eth0|eth1|eth2|eth3"|grep ixgbe|wc -l`
    NUM_IXGBE_eth0=`cat /tmp/hwconfig|grep eth0|grep ixgbe|wc -l`

    echo "$NUM_NIC-$NUM_IXGBE_NIC-$NUM_IXGBE_eth0"

    function ch_nic() {
        cp /etc/udev/rules.d/70-persistent-net.rules  /etc/udev/rules.d/70-persistent-net.rules_bak
        sed -i 's/\"eth2\"/\"eth0_bak\"/g' /etc/udev/rules.d/70-persistent-net.rules
        sed -i 's/\"eth3\"/\"eth1_bak\"/g' /etc/udev/rules.d/70-persistent-net.rules
        sed -i 's/\"eth0\"/\"eth2\"/g' /etc/udev/rules.d/70-persistent-net.rules
        sed -i 's/\"eth1\"/\"eth3\"/g' /etc/udev/rules.d/70-persistent-net.rules
        sed -i 's/\"eth0_bak\"/\"eth0\"/g' /etc/udev/rules.d/70-persistent-net.rules
        sed -i 's/\"eth1_bak\"/\"eth1\"/g' /etc/udev/rules.d/70-persistent-net.rules
        diff /etc/udev/rules.d/70-persistent-net.rules  /etc/udev/rules.d/70-persistent-net.rules_bak
    }

    if [ ! -f /etc/udev/rules.d/70-persistent-net.rules_bak ]; then
        if [ $NUM_NIC == "4" ] && [ $NUM_IXGBE_NIC == "2" ];then
            if [ $NUM_IXGBE_eth0 == "1" ] && [ $NODE_TYPE == "Compute" ];then
                ch_nic
            elif [ $NUM_IXGBE_eth0 == "0" ] && [ $NODE_TYPE == "Controller" ];then
                ch_nic
            else
                echo "pass"
            fi
        fi
    else
        echo '70-persistent-net.rules is changed'
    fi
}


if [ -n "$NIC_DEFAULT" ]; then
IP=`cat /etc/sysconfig/network-scripts/ifcfg-$NIC_DEFAULT | grep IPADDR | cut -d "=" -f 2`
NETMASK=`cat /etc/sysconfig/network-scripts/ifcfg-$NIC_DEFAULT | grep NETMASK | cut -d "=" -f 2`
GATEWAY=`cat /etc/sysconfig/network-scripts/ifcfg-$NIC_DEFAULT | grep GATEWAY | cut -d "=" -f 2`
fi

if [ -n "$NIC_NEI" ]; then
IP_1=`cat /etc/sysconfig/network-scripts/ifcfg-$NIC_NEI | grep IPADDR | cut -d "=" -f 2`
NETMASK_1=`cat /etc/sysconfig/network-scripts/ifcfg-$NIC_NEI | grep NETMASK | cut -d "=" -f 2`
GATEWAY_1=`cat /etc/sysconfig/network-scripts/ifcfg-$NIC_NEI | grep GATEWAY | cut -d "=" -f 2`
ROUTE_1=`cat /etc/sysconfig/network-scripts/route-$NIC_NEI`
fi



#***********************************************************************
havana_2_hw () {
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
IPADDR=$IP_1
NETMASK=$NETMASK_1
DELAY=0
EOF

mv /etc/sysconfig/network-scripts/route-$NIC_NEI /tmp
echo $ROUTE_1 > /etc/sysconfig/network-scripts/route-br1:1

more /etc/sysconfig/network-scripts/ifcfg-br1:1
more /etc/sysconfig/network-scripts/ifcfg-br0:1
more /etc/sysconfig/network-scripts/route-br1:1

echo " >>>>> br0/br0:1($IP) --> eth0(access); br1/br1:1(privateIP) --> eth1(access)"
}
#***********************************************************************
havana_2_gn () {
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

cat > /etc/sysconfig/network-scripts/ifcfg-br1:1 << EOF
DEVICE=br1:1
BOOTPROTO=static
ONBOOT=yes
TYPE=Bridge
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
DELAY=0
EOF

/etc/sysconfig/network-scripts/ifcfg-br1:1
echo " >>>>> br0 --> eth0(access); br1/br1:1($IP) --> eth1(access)"
}
#***********************************************************************
icehouse_2_hw () {
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

mv /etc/sysconfig/network-scripts/route-$NIC_NEI /tmp
echo $ROUTE_1 > /etc/sysconfig/network-scripts/route-br0:1


more /etc/sysconfig/network-scripts/ifcfg-br0
more /etc/sysconfig/network-scripts/ifcfg-br0:1
more /etc/sysconfig/network-scripts/route-br0:1

}
#***********************************************************************
havana_4_gn () {
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
BONDING_OPTS="miimon=100 mode=4"
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

more /etc/sysconfig/network-scripts/ifcfg-br1:1
echo "alias bond0 bond1 bonding" > /etc/modprobe.d/bonding.conf
echo " >>>>> br0 --> bond0[(eth0,eth1)lacp,access]; br1:1($IP) --> br1 --> bond1[(eth2,eth3)lacp,access]"
}
#***********************************************************************
icehouse_4_gn () {
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

cat > /etc/sysconfig/network-scripts/ifcfg-bond0 << EOF
DEVICE=bond0
BOOTPROTO=none
ONBOOT=yes
USERCTL=no
BRIDGE=br0
BONDING_OPTS="miimon=100 mode=4"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 << EOF
DEVICE=br0
ONBOOT=yes
BOOTPROTO=static
IPADDR=$IP
NETMASK=$NETMASK
GATEWAY=$GATEWAY
TYPE=Bridge
DELAY=0
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 << EOF
DEVICE=eth2
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth3 << EOF
DEVICE=eth3
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
EOF

more /etc/sysconfig/network-scripts/ifcfg-br0
echo "alias bond0 bonding" > /etc/modprobe.d/bonding.conf
echo " >>>>> br0($IP) --> bond0[(eth0,eth1)lacp,access]; [(eth2,eth3)lacp,trunk]"
}
#***********************************************************************
icehouse_4_hw () {
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=none
SLAVE=yes
MASTER=bond0
USERCTL=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=none
SLAVE=yes
MASTER=bond0
USERCTL=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-bond0 << EOF
DEVICE=bond0
BOOTPROTO=none
ONBOOT=yes
USERCTL=no
BRIDGE=br0
BONDING_OPTS="miimon=100 mode=4"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 << EOF
DEVICE=br0
ONBOOT=yes
BOOTPROTO=static
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

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 << EOF
DEVICE=eth2
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth3 << EOF
DEVICE=eth3
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
EOF

mv /etc/sysconfig/network-scripts/route-$NIC_NEI /tmp
echo $ROUTE_1 > /etc/sysconfig/network-scripts/route-br0:1

more /etc/sysconfig/network-scripts/ifcfg-br0
more /etc/sysconfig/network-scripts/ifcfg-br0:1
more /etc/sysconfig/network-scripts/route-br0:1

echo "alias bond0 bonding" > /etc/modprobe.d/bonding.conf
echo " >>>>> br0($IP)/br0:1(privateIP) --> bond0[(eth0,eth1)lacp,access]; [(eth2,eth3)lacp,trunk]"
}

other_down () {
for i in `seq $1 7`;do
test -f /etc/sysconfig/network-scripts/ifcfg-eth$i && cat > /etc/sysconfig/network-scripts/ifcfg-eth$i << EOF
DEVICE=eth$i
ONBOOT=no
BOOTPROTO=none
TYPE=Ethernet
EOF
done
}

#***********************************************************************
network_restart () {
service network restart &
service network restart &
}

case $1 in   
   
        "havana-2-hw")   
               havana_2_hw   
               other_down 2
           #network_restart
                ;;   
   
        "havana-2-gn")   
               havana_2_gn  
               other_down 2
           network_restart 
                ;;   
   
        "icehouse-2-hw")   
               icehouse_2_hw 
               other_down 2
           #network_restart  
               ;;   
   
        "havana-4-gn")   
               havana_4_gn   
               other_down 4
               nic_ixgbe_change
           network_restart
               ;;   
   
        "icehouse-4-gn")   
               icehouse_4_gn   
               other_down 4
               nic_ixgbe_change
           network_restart
               ;;  

        "icehouse-4-hw")   
               icehouse_4_hw
               other_down 4
               nic_ixgbe_change
           #network_restart
               ;;  

        *)   
          echo   
                echo  "Usage: $0 {havana-2-hw|havana-2-gn|icehouse-2-hw|havana-4-gn|icehouse-4-gn|icehouse-4-hw}"   
          echo   
esac
