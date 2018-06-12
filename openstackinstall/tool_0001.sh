#!/bin/bash
# use by natserver to change 10Gb NIC order~!

IXGBE_NIC_NUM=`grep 'ixgbe' /etc/udev/rules.d/70-persistent-net.rules | wc -l`
if [ "$IXGBE_NIC_NUM" -gt "0" ]; then
        for NIC in $(grep 'KERNEL' /etc/udev/rules.d/70-persistent-net.rules | awk -F "," '{print $7}' | cut -d '"' -f 2 | sort -d)
        do
                IXGBE_NIC=`ethtool -i $NIC | grep -c ixgbe`
                if [ "$IXGBE_NIC" -eq "1" ]; then
                        # echo $IXGBE_NIC
                        # echo $NIC
                        NIC_ID=`echo $NIC | sed 's/[A-Z a-z]//g'`
                        if [ $(($NIC_ID%2)) == 0 ] && [ $NIC_ID != 0 ]; then
                                CHANGE_NIC=$(grep 'KERNEL' /etc/udev/rules.d/70-persistent-net.rules | awk -F "," '{print $7}' | cut -d '"' -f 2 | sort -d | awk 'NR==1')
                                CHANGE_NIC_ID=$(echo $CHANGE_NIC | sed 's/[A-Z a-z]//g')
                                mv /etc/sysconfig/network-scripts/ifcfg-$CHANGE_NIC /etc/sysconfig/network-scripts/ifcfg-${CHANGE_NIC}_bak
                                sed -i "s/$CHANGE_NIC/${CHANGE_NIC}_bak/g" /etc/udev/rules.d/70-persistent-net.rules
                                mv /etc/sysconfig/network-scripts/ifcfg-$NIC /etc/sysconfig/network-scripts/ifcfg-$CHANGE_NIC
                                sed -i "/DEVICE/ s/$NIC_ID/$CHANGE_NIC_ID/" /etc/sysconfig/network-scripts/ifcfg-$CHANGE_NIC
                                sed -i "s/$NIC/$CHANGE_NIC/g" /etc/udev/rules.d/70-persistent-net.rules
                                sed -i "s/${CHANGE_NIC}_bak/$NIC/g" /etc/udev/rules.d/70-persistent-net.rules
                                mv /etc/sysconfig/network-scripts/ifcfg-${CHANGE_NIC}_bak /etc/sysconfig/network-scripts/ifcfg-$NIC
                                sed -i "/DEVICE/ s/$CHANGE_NIC_ID/$NIC_ID/" /etc/sysconfig/network-scripts/ifcfg-$NIC

                                if [ -n "`route -n | grep 10.0.0.0 | awk '{print $NF}'`" ] && [ "`route -n | grep 10.0.0.0 | awk '{print $NF}'`" = "$NIC" ]; then
                                        mv /etc/sysconfig/network-scripts/route-$NIC /etc/sysconfig/network-scripts/route-$CHANGE_NIC
                                fi
                        elif [ $NIC_ID != 1 ]; then
                                CHANGE_NIC=$(grep 'KERNEL' /etc/udev/rules.d/70-persistent-net.rules | awk -F "," '{print $7}' | cut -d '"' -f 2 | sort -d | awk 'NR==2')
                                CHANGE_NIC_ID=$(echo $CHANGE_NIC | sed 's/[A-Z a-z]//g')
                                mv /etc/sysconfig/network-scripts/ifcfg-$CHANGE_NIC /etc/sysconfig/network-scripts/ifcfg-${CHANGE_NIC}_bak
                                sed -i "s/$CHANGE_NIC/${CHANGE_NIC}_bak/g" /etc/udev/rules.d/70-persistent-net.rules
                                mv /etc/sysconfig/network-scripts/ifcfg-$NIC /etc/sysconfig/network-scripts/ifcfg-$CHANGE_NIC
                                sed -i "/DEVICE/ s/$NIC_ID/$CHANGE_NIC_ID/" /etc/sysconfig/network-scripts/ifcfg-$CHANGE_NIC
                                sed -i "s/$NIC/$CHANGE_NIC/g" /etc/udev/rules.d/70-persistent-net.rules
                                sed -i "s/${CHANGE_NIC}_bak/$NIC/g" /etc/udev/rules.d/70-persistent-net.rules
                                mv /etc/sysconfig/network-scripts/ifcfg-${CHANGE_NIC}_bak /etc/sysconfig/network-scripts/ifcfg-$NIC
                                sed -i "/DEVICE/ s/$CHANGE_NIC_ID/$NIC_ID/" /etc/sysconfig/network-scripts/ifcfg-$NIC

                                if [ -n "`route -n | grep 10.0.0.0 | awk '{print $NF}'`" ] && [ "`route -n | grep 10.0.0.0 | awk '{print $NF}'`" = "$NIC" ]; then
                                        mv /etc/sysconfig/network-scripts/route-$NIC /etc/sysconfig/network-scripts/route-$CHANGE_NIC
                                fi
                        else
                                echo " >>>>>>> 10Gb network card not found or had is eth0 and eth1~!"
                        fi
                fi
        done
fi

