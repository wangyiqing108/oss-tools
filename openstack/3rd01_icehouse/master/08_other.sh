#!/bin/bash

rabbitmq_management_count=`netstat -nltp|grep 15672|wc -l`
if [ $rabbitmq_management_count == 0 ];then
    /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management 
    rabbitmqctl add_user rabbitmqadmin JTd3JbnBGsc#%2
    rabbitmqctl set_user_tags rabbitmqadmin administrator
    rabbitmqctl set_permissions -p / rabbitmqadmin ".*" ".*" ".*"
    /etc/init.d/rabbitmq-server restart
fi
