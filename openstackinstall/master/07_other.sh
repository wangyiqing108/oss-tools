#!/bin/bash
# add controller crontab
echo "* * * * 1 keystone-manage token_flush > /dev/null 2>&1" >> /var/spool/cron/root 
crontab -l

# add openstack zabbix
userparams_count=$(grep -c 'check Openstack API' /usr/local/zabbix/conf/zabbix_agentd.userparams.conf)

if [ $userparams_count == 0 ];then
cat >> /usr/local/zabbix/conf/zabbix_agentd.userparams.conf  << EOF

#check Ceph 
UserParameter=ceph.health, /usr/local/zabbix/script/check_ceph.sh health
UserParameter=ceph.osd_in, /usr/local/zabbix/script/check_ceph.sh in
UserParameter=ceph.osd_up, /usr/local/zabbix/script/check_ceph.sh up
UserParameter=ceph.active, /usr/local/zabbix/script/check_ceph.sh active
UserParameter=ceph.backfill, /usr/local/zabbix/script/check_ceph.sh backfill
UserParameter=ceph.clean, /usr/local/zabbix/script/check_ceph.sh clean
UserParameter=ceph.creating, /usr/local/zabbix/script/check_ceph.sh creating
UserParameter=ceph.degraded, /usr/local/zabbix/script/check_ceph.sh degraded
UserParameter=ceph.degraded_percent, /usr/local/zabbix/script/check_ceph.sh degraded_percent
UserParameter=ceph.down, /usr/local/zabbix/script/check_ceph.sh down
UserParameter=ceph.incomplete, /usr/local/zabbix/script/check_ceph.sh incomplete
UserParameter=ceph.inconsistent, /usr/local/zabbix/script/check_ceph.sh inconsistent
UserParameter=ceph.peering, /usr/local/zabbix/script/check_ceph.sh peering
UserParameter=ceph.recovering, /usr/local/zabbix/script/check_ceph.sh recovering
UserParameter=ceph.remapped, /usr/local/zabbix/script/check_ceph.sh remapped
UserParameter=ceph.repair, /usr/local/zabbix/script/check_ceph.sh repair
UserParameter=ceph.replay, /usr/local/zabbix/script/check_ceph.sh replay
UserParameter=ceph.scrubbing, /usr/local/zabbix/script/check_ceph.sh scrubbing
UserParameter=ceph.splitting, /usr/local/zabbix/script/check_ceph.sh splitting
UserParameter=ceph.stale, /usr/local/zabbix/script/check_ceph.sh stale
UserParameter=ceph.pgtotal, /usr/local/zabbix/script/check_ceph.sh pgtotal
UserParameter=ceph.waitBackfill, /usr/local/zabbix/script/check_ceph.sh waitBackfill
UserParameter=ceph.mon, /usr/local/zabbix/script/check_ceph.sh mon
UserParameter=ceph.rados_total, /usr/local/zabbix/script/check_ceph.sh rados_total
UserParameter=ceph.rados_used, /usr/local/zabbix/script/check_ceph.sh rados_used
UserParameter=ceph.rados_free, /usr/local/zabbix/script/check_ceph.sh rados_free
UserParameter=ceph.wrbps, /usr/local/zabbix/script/check_ceph.sh wrbps
UserParameter=ceph.rdbps, /usr/local/zabbix/script/check_ceph.sh rdbps
UserParameter=ceph.ops, /usr/local/zabbix/script/check_ceph.sh ops

#check Openstack API
UserParameter=cinder.api.status, /usr/local/zabbix/script/check_openstack_api.py cinder http $HOSTNAME 8776
UserParameter=glance.api.status, /usr/local/zabbix/script/check_openstack_api.py glance http $HOSTNAME 9292
UserParameter=keystone.api.status, /usr/local/zabbix/script/check_openstack_api.py keystone http $HOSTNAME 5000
UserParameter=keystone.service.api.status, /usr/local/zabbix/script/check_openstack_api.py keystone_service http $HOSTNAME 35357
UserParameter=neutron.api.status, /usr/local/zabbix/script/check_openstack_api.py neutron http $HOSTNAME 9696
UserParameter=nova.api.status, /usr/local/zabbix/script/check_openstack_api.py nova_os http $HOSTNAME 8774

#check Openstack RabbitMQ
UserParameter=rabbitmq.queue.items, /usr/local/zabbix/script/check_rabbit.py queues-items
UserParameter=rabbitmq.queues.without.consumers, /usr/local/zabbix/script/check_rabbit.py queues-without-consumers
UserParameter=rabbitmq.missing.nodes, /usr/local/zabbix/script/check_rabbit.py missing-nodes
UserParameter=rabbitmq.unmirror.queues, /usr/local/zabbix/script/check_rabbit.py unmirror-queues
UserParameter=rabbitmq.missing.queues, /usr/local/zabbix/script/check_rabbit.py missing-queues

#check Openstack Cluster state
UserParameter=db.token.count.query, /usr/local/zabbix/script/check_openstack_db.py token_count
UserParameter=db.instance.error.query, /usr/local/zabbix/script/check_openstack_db.py instance_error
UserParameter=db.services.offline.nova.query, /usr/local/zabbix/script/check_openstack_db.py services_offline_nova
UserParameter=db.instance.count.query, /usr/local/zabbix/script/check_openstack_db.py instance_count
UserParameter=db.cpu.total.query, /usr/local/zabbix/script/check_openstack_db.py cpu_total
UserParameter=db.cpu.used.query, /usr/local/zabbix/script/check_openstack_db.py cpu_used
UserParameter=db.ram.total.query, /usr/local/zabbix/script/check_openstack_db.py ram_total
UserParameter=db.ram.used.query, /usr/local/zabbix/script/check_openstack_db.py ram_used
UserParameter=db.services.offline.cinder.query, /usr/local/zabbix/script/check_openstack_db.py services_offline_cinder
UserParameter=db.instance.count.max, /usr/local/zabbix/script/check_openstack_instances.sh max_instances
UserParameter=db.instance.count.free, /usr/local/zabbix/script/check_openstack_instances.sh free_instances
EOF
fi

rabbitmq_management_count=`netstat -nltp|grep 15672|wc -l`
if [ $rabbitmq_management_count == 0 ];then
    /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management 
    rabbitmqctl add_user rabbitmqadmin JTd3JbnBGsc#%2
    rabbitmqctl set_user_tags rabbitmqadmin administrator
    rabbitmqctl set_permissions -p / rabbitmqadmin ".*" ".*" ".*"
    /etc/init.d/rabbitmq-server restart
fi

test -d /etc/zabbix || mkdir /etc/zabbix
wget -q http://10.200.93.170:8080/Tools/ops-tools/openstack/zabbix/scripts/check_ceph.sh -O /usr/local/zabbix/script/check_ceph.sh  
wget -q http://10.200.93.170:8080/Tools/ops-tools/openstack/zabbix/scripts/check_rabbit.py -O /usr/local/zabbix/script/check_rabbit.py  
wget -q http://10.200.93.170:8080/Tools/ops-tools/openstack/zabbix/scripts/check_openstack_db.py -O /usr/local/zabbix/script/check_openstack_db.py  
wget -q http://10.200.93.170:8080/Tools/ops-tools/openstack/zabbix/scripts/check_openstack_api.py -O /usr/local/zabbix/script/check_openstack_api.py  
wget -q http://10.200.93.170:8080/Tools/ops-tools/openstack/zabbix/scripts/check_openstack_instances.sh -O /usr/local/zabbix/script/check_openstack_instances.sh

wget -q http://10.200.93.170:8080/Tools/ops-tools/openstack/zabbix/conf/check_db.conf -O /etc/zabbix/check_db.conf 
wget -q http://10.200.93.170:8080/Tools/ops-tools/openstack/zabbix/conf/check_api.conf -O /etc/zabbix/check_api.conf 
wget -q http://10.200.93.170:8080/Tools/ops-tools/openstack/zabbix/conf/check_rabbit.conf -O /etc/zabbix/check_rabbit.conf 

if [ `grep -cw sql_connection /etc/nova/nova.conf` == 1 ];then
    openstack-config --set /etc/zabbix/check_db.conf query_db nova_db_conn $(openstack-config --get /etc/nova/nova.conf database sql_connection)
else
    openstack-config --set /etc/zabbix/check_db.conf query_db nova_db_conn $(openstack-config --get /etc/nova/nova.conf database connection)
fi
if [ `grep -cw sql_connection /etc/keystone/keystone.conf` == 1 ];then 
    openstack-config --set /etc/zabbix/check_db.conf query_db keystone_db_conn $(openstack-config --get /etc/keystone/keystone.conf database sql_connection)
else
    openstack-config --set /etc/zabbix/check_db.conf query_db keystone_db_conn $(openstack-config --get /etc/keystone/keystone.conf database connection)
fi
test -f /etc/cinder/cinder.conf && openstack-config --set /etc/zabbix/check_db.conf query_db cinder_db_conn $(openstack-config --get /etc/cinder/cinder.conf database connection)
chmod +x /usr/local/zabbix/script/*

echo -n "free_instances: ";/usr/local/zabbix/script/check_openstack_instances.sh free_instances
echo -n "check_nova: ";/usr/local/zabbix/script/check_openstack_api.py nova_os http $HOSTNAME 8774
echo -n "token_count: ";/usr/local/zabbix/script/check_openstack_db.py token_count
test -f /etc/ceph/ceph.conf && echo -n "ceph health " && /usr/local/zabbix/script/check_ceph.sh health
echo -n "rabbitmq queues-items ";/usr/local/zabbix/script/check_rabbit.py queues-items
