#!/bin/bash
for vm in `nova list --all-tenant|grep SHUTOFF|awk '{print $2}'`
do
    updated=`nova show $vm|grep updated|awk '{print $4}'`
    updated=`echo $updated|sed 's/-/\//g'|sed 's/T/ /g'`
    updated=`date -d "$updated" +%s`
    NOW=`date +%s`
    SHUTDOWN_DAYS=$((($NOW-$updated)/3600/24))
    if [ $SHUTDOWN_DAYS -gt 7 ]; then
        echo "deleting $vm"
        nova delete $vm
    fi
done

