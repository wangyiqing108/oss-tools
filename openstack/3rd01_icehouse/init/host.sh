#!/bin/bash
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.148.10.248 m-10-248-test02-yz.bj-cn.vps.letv.cn
10.148.10.244 m-10-244-test02-yz.bj-cn.vps.letv.cn m-10-244-test02-yz
10.148.10.250 m-10-250-test02-yz.bj-cn.vps.letv.cn m-10-250-test02-yz
10.148.10.246 c-10-246-test02-yz.bj-cn.vps.letv.cn
10.148.10.247 c-10-247-test02-yz.bj-cn.vps.letv.cn
10.148.10.245 c-10-245-test02-yz.bj-cn.vps.letv.cn
10.148.10.251 c-10-251-test02-yz.bj-cn.vps.letv.cn
10.148.10.252 c-10-252-test02-yz.bj-cn.vps.letv.cn
10.148.10.253 c-10-253-test02-yz.bj-cn.vps.letv.cn
#mysql
10.200.84.30 mysqlserver
EOF
#more /etc/hosts
HOSTNAME=`cat /etc/hosts | grep $(ifconfig br0 | grep "inet addr" | awk '{print $2}' | cut -d ":" -f 2) | awk '{print $2}'`
hostname $HOSTNAME
sed -i "/^HOSTNAME/d" /etc/sysconfig/network
echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
more /etc/sysconfig/network


