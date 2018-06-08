#!/bin/bash
service=$1
mysql_host='mysqlserver'
if [ $service = "glance" ];then
    password=$(cat /etc/${service}/${service}-api.conf|grep -F 'connection = '|awk -F ":" '{print $3}'|awk -F'@' '{print $1}')
    port=$(cat /etc/${service}/${service}-api.conf|grep -F 'connection = '|awk -F ":" '{print $4}'|awk -F'/' '{print $1}')
else
    password=$(cat /etc/${service}/${service}.conf|grep -F 'connection = '|awk -F ":" '{print $3}'|awk -F'@' '{print $1}')
    port=$(cat /etc/${service}/${service}.conf|grep -F 'connection = '|awk -F ":" '{print $4}'|awk -F'/' '{print $1}')
fi
mysql -u${service} -p${password} -P${port} -h${mysql_host} ${service}
