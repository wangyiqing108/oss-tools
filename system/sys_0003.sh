#!/bin/bash
# sys_0003.sh
# nic overruns > 100 pkt/s

netdev_max_backlog=25000

# modify ring buffer
ethtool -G eth0 rx 4096 tx 4096
ethtool -G eth1 rx 4096 tx 4096
ethtool -G eth2 rx 4096 tx 4096
ethtool -G eth3 rx 4096 tx 4096

# modify net.core.netdev_max_backlog
cat /etc/sysctl.conf | grep "netdev_max_backlog"
if [ $? == 0 ];then
    sysctl -w net.core.netdev_max_backlog=$netdev_max_backlog
    sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
    echo "net.core.netdev_max_backlog = $netdev_max_backlog" >> /etc/sysctl.conf
    sysctl -p
else
    echo "net.core.netdev_max_backlog = $netdev_max_backlog" >> /etc/sysctl.conf
    sysctl -p
fi
