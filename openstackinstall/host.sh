#!/bin/bash
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.112.22.200  m-22-200-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.201  m-22-201-wj01-tdxy.bj-cn.vps.letv.cn m-22-201-wj01-tdxy
10.112.22.202  m-22-202-wj01-tdxy.bj-cn.vps.letv.cn m-22-202-wj01-tdxy
10.112.22.11  c-22-11-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.12  c-22-12-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.13  c-22-13-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.14  c-22-14-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.15  c-22-15-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.16  c-22-16-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.17  c-22-17-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.18  c-22-18-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.19  c-22-19-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.21  c-22-21-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.22  c-22-22-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.23  c-22-23-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.24  c-22-24-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.25  c-22-25-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.26  c-22-26-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.27  c-22-27-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.28  c-22-28-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.29  c-22-29-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.31  c-22-31-wj01-tdxy.bj-cn.vps.letv.cn
10.112.22.41  c-22-41-wj01-tdxy.bj-cn.vps.letv.cn

# Mysql:
10.110.50.178 mysqlserver
EOF
#more /etc/hosts
HOSTNAME=`cat /etc/hosts | grep $(ifconfig br0 | grep "inet addr" | awk '{print $2}' | cut -d ":" -f 2) | awk '{print $2}'`
hostname $HOSTNAME
sed -i "/^HOSTNAME/d" /etc/sysconfig/network
echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
more /etc/sysconfig/network
