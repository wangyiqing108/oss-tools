#!/bin/bash
# sys_0004.sh
# Kipmi0 cpu time > 100

# modify kipmid_max_busy_us
echo 100 > /sys/module/ipmi_si/parameters/kipmid_max_busy_us

# modify net.core.netdev_max_backloga
if [ -f /etc/modprobe.d/ipmi.conf ];then
    grep -q 'options ipmi_si kipmid_max_busy_us=100' /etc/modprobe.d/ipmi.conf || \
    echo 'options ipmi_si kipmid_max_busy_us=100' > /etc/modprobe.d/ipmi.conf
else
    echo 'options ipmi_si kipmid_max_busy_us=100' > /etc/modprobe.d/ipmi.conf
fi

