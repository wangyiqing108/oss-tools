#!/bin/sh

#install falcon-agent
if  ! (rpm -q falcon-agent >/dev/null)  ;then
    yum install falcon-agent -y
fi

IP_FOURTH=`hostname|awk -F '.' '{print $1}' |awk -F '-' '{print $NF}'`

TRANSFER=falconserver
HBS=falconserver

AZ=az1
REGION=`hostname |awk -F '.' '{print $2}'`

OS_PASSWORD='b13e5730698ca861'

RABBIT_USER=rabbitmqadmin
RABBIT_PASS=JTd3JbnBGsc#%2
RABBIT_PORT=18887

if [ $IP_FOURTH = 200 ]; then
    RABBIT_HOST=rabbitmq-a
elif [ $IP_FOURTH = 201 ]; then
    RABBIT_HOST=rabbitmq-b
fi


NOVA_DB_USER=nova
NOVA_DB_PASS=f77463fb8a
NOVA_DB_PORT=4406

KEYSTONE_DB_USER=keystone
KEYSTONE_DB_PASS=6b7f426cf2
KEYSTONE_DB_PORT=4406

CINDER_DB_USER=cinder
CINDER_DB_PASS=ZjQzMzNkNzQ0MTU
CINDER_DB_PORT=4406

cat > /usr/local/falcon-agent/cfg.json << EOF


{ 
    "debug": true, 
    "hostname": "", 
    "ip": "", 
    "plugin": { 
        "enabled": true, 
        "dir": "./plugin", 
        "git": "https://github.com/open-falcon/plugin.git", 
        "logs": "./logs" 
    }, 
    "heartbeat": { 
        "enabled": true, 
        "addr": "$HBS:6030", 
        "interval": 60, 
        "timeout": 1000 
    }, 
    "transfer": { 
        "enabled": true, 
        "addrs": [ 
            "$TRANSFER:8433" 
        ], 
        "interval": 60, 
        "timeout": 1000 
    }, 
    "http": { 
        "enabled": false, 
        "listen": ":1988", 
        "backdoor": false 
    }, 
    "collector": { 
        "ifacePrefix": ["eth", "em", "bond"] 
    }, 
    "ignore": { 
    } 
} 

EOF

if [ $IP_FOURTH = 200 ] || [ $IP_FOURTH = 201 ]; then

cat > /usr/local/falcon-agent/plugin/openstack-conf/check_api.conf << EOF

[api]
log_level=CRITICAL
service_hostname=127.0.0.1
user=admin
user_domain=default
password=$OS_PASSWORD
endpoint=openstack-$REGION
keystone_endpoints=http://keystone.${REGION}.lcs.i-lecloud.com:35357/v3
nova_os_map=v2.1
glance_map=v1/images
keystone_service_map=v3
keystone_map=v3
cinder_map=v1
neutron_map=
nova_os_timeout=5
glance_timeout=5
keystone_service_timeout=5
keystone_timeout=5
cinder_timeout=5
neutron_timeout=5
    
EOF
    
cat > /usr/local/falcon-agent/plugin/openstack-conf/check_db.conf << EOF

[query_db]
log_level=CRITICAL
#password is db password
keystone_db_conn=mysql://$KEYSTONE_DB_USER:$KEYSTONE_DB_PASS@mysqlserver:$KEYSTONE_DB_PORT/keystone
nova_db_conn=mysql://$NOVA_DB_USER:$NOVA_DB_PASS@mysqlserver:$NOVA_DB_PORT/nova
cinder_db_conn=mysql://$CINDER_DB_USER:$CINDER_DB_PASS@mysqlserver:$CINDER_DB_PORT/cinder

endpoint=openstack-$REGION

#Count tokens in keystone db
token_count_connection=keystone_db_conn
token_count_query=select count(*) from token

#Count instances in error state
instance_error_connection=nova_db_conn
instance_error_query=select count(*) from instances where vm_state='error' and deleted=0

#Count offline services - nova
services_offline_nova_connection=nova_db_conn
services_offline_nova_query=select count(*) from services where disabled=0 and deleted=0 and timestampdiff(SECOND,updated_at,utc_timestamp())>60

#Count online services - nova compute
services_online_nova_connection=nova_db_conn
services_online_nova_query=select count(*) from services where topic = 'compute' and timestampdiff(SECOND,updated_at,utc_timestamp())<60;

#Count running instances
instance_count_connection=nova_db_conn
instance_count_query=select count(*) from instances where deleted=0 and vm_state='active'

#Sum all vcpus in cluster
cpu_total_connection=nova_db_conn
cpu_total_query=select ifnull(sum(vcpus), 0) from compute_nodes where deleted=0

#Sum used vcpus in cluster
cpu_used_connection=nova_db_conn
cpu_used_query=select ifnull(sum(vcpus), 0) from instances where deleted=0 and vm_state='active'

#Sum all memory in cluster
ram_total_connection=nova_db_conn
ram_total_query=select ifnull(sum(memory_mb), 0) from compute_nodes where deleted=0

#Sum used memory in cluster
ram_used_connection=nova_db_conn
ram_used_query=select ifnull(sum(memory_mb), 0) from instances where deleted=0 and vm_state='active'

#Count offline services - cinder
services_offline_cinder_connection=cinder_db_conn
services_offline_cinder_query=select count(*) from services where disabled=0 and deleted=0 and timestampdiff(SECOND,updated_at,utc_timestamp())>60
    
EOF
    
    
cat > /usr/local/falcon-agent/plugin/openstack-conf/check_rabbit.conf << EOF
[rabbitmq]
log_level=DEBUG
endpoint=openstack-${REGION}
user=$RABBIT_USER
password=$RABBIT_PASS
host=http://$RABBIT_HOST:$RABBIT_PORT
#OpenStack queues, Y - number of service types, N - count of *this* service, max_queues=Y*(2*N+1)
max_queues=128
    
EOF
    
fi

systemctl enable falcon-agent
systemctl restart falcon-agent
systemctl status falcon-agent
