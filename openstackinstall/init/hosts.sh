#!/bin/bash
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.11.143.201   m-143-201-dev01-yz.bj-cn.vps.letv.cn   m-143-201-dev01-yz
10.11.143.202   m-143-202-dev01-yz.bj-cn.vps.letv.cn   m-143-202-dev01-yz
10.11.143.11   c-143-11-dev01-yz.bj-cn.vps.letv.cn
10.11.143.12   c-143-12-dev01-yz.bj-cn.vps.letv.cn
#mysql
10.130.91.241  mysqlserver
EOF
#more /etc/hosts
HOSTNAME=`cat /etc/hosts | grep $(ifconfig br0 | grep "inet addr" | awk '{print $2}' | cut -d ":" -f 2) | awk '{print $2}'`
hostname $HOSTNAME
sed -i "/^HOSTNAME/d" /etc/sysconfig/network
echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
more /etc/sysconfig/network


