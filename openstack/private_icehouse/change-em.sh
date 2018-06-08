#!/bin/bash
EM_SUM=`more /etc/udev/rules.d/70-persistent-net.rules | grep em | wc -l`
for (( m=1; m<=${EM_SUM}; m++));
do
n=$((m-1))
sed -i 's/em${m}/eth${n}' /etc/udev/rules.d/70-persistent-net.rules
sed -i 's/em${m}/eth${n}' /etc/sysconfig/network-scripts/ifcfg-em${m}
mv /etc/sysconfig/network-scripts/ifcfg-em${m} /etc/sysconfig/network-scripts/ifcfg-eth${n}
done
rmmod igb ; modprobe igb ; service network restart ; service network restart &
echo "please reboot server !" 

