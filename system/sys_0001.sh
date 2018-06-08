#!/bin/bash
# sys_0001.sh
# kernel: nf_conntrack: table full, dropping packet.
#
mem=`free -g | grep "Mem" |awk '{print $2}'`
conn=$[ $mem*32768 ]
hashsz=$[ $conn /4 ]

# modify sysctl nf_conntrack_max #

cat /etc/sysctl.conf | grep "nf_conntrack_max"
if [ $? == 0 ];then
    sysctl -w net.netfilter.nf_conntrack_max=$conn
    sed -i '/net.nf_conntrack_max/d' /etc/sysctl.conf
    echo "net.nf_conntrack_max = $conn" >> /etc/sysctl.conf
    sysctl -p
else
    echo "net.nf_conntrack_max=$conn" >> /etc/sysctl.conf
    sysctl -p
fi

# modify /etc/modprobe.d/nf_conntrack.conf #

sed -i '/nf_conntrack hashsize/d' /etc/modprobe.d/nf_conntrack.conf
echo "options nf_conntrack hashsize=$hashsz" >>  /etc/modprobe.d/nf_conntrack.conf

# close packets checksum  #

sysctl -a | grep "nf_conntrack_checksum = 1"
if [ $? == 0 ];then
    sysctl -w net.netfilter.nf_conntrack_checksum=0
fi

# modfiy keepalive #

keeplive_time=`sysctl -a | grep "net.ipv4.tcp_keepalive_time" | awk '{print $3}'`
keepalive_probes=`sysctl -a | grep "net.ipv4.tcp_keepalive_probes" | awk '{print $3}'`
keepalive_intvl=`sysctl -a | grep "net.ipv4.tcp_keepalive_intvl" | awk '{print $3}'`
redundancy_time=5
total=$[ $keeplive_time + $keepalive_probes * $keepalive_intvl + $redundancy_time ]
sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=$total

