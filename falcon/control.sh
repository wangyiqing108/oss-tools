#!/bin/sh

if [ $# = 1 ];then

service=`systemctl list-unit-files |grep falcon |grep enable |awk '{print $1}'`
for i in $service;do
    systemctl $1 $i
done

else
    echo "$0 status|start|stop|restart."
fi
