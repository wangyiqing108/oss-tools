#!/bin/bash
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.185.8.200  m-8-200-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.201  m-8-201-pro01-mjq.bj-cn.vps.letv.cn m-8-201-pro01-mjq
10.185.8.202  m-8-202-pro01-mjq.bj-cn.vps.letv.cn m-8-202-pro01-mjq
10.185.8.10  c-8-10-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.11  c-8-11-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.12  c-8-12-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.13  c-8-13-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.14  c-8-14-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.15  c-8-15-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.16  c-8-16-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.17  c-8-17-pro01-mjq.bj-cn.vps.letv.cn
10.185.8.18  c-8-18-pro01-mjq.bj-cn.vps.letv.cn

#mysql
10.150.130.222 mysqlserver
EOF
#more /etc/hosts
# 国内
HOSTNAME=`cat /etc/hosts | grep -w $(ifconfig br0 | grep "inet addr" | awk '{print $2}' | cut -d ":" -f 2) | awk '{print $2}'`
# 海外
HOSTNAME=`cat /etc/hosts | grep -w $(ifconfig br0:1 | grep "inet addr" | awk '{print $2}' | cut -d ":" -f 2) | awk '{print $2}'`

hostname $HOSTNAME
sed -i "/^HOSTNAME/d" /etc/sysconfig/network
echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
more /etc/sysconfig/network