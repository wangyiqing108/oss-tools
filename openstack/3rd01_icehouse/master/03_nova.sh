#!/bin/bash

source ./master.conf

MASTER_NAME=`echo $HOSTNAME | grep 201`
MASTER_IP=`more /etc/hosts | grep $HOSTNAME | awk '{print $1}'`

echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"

#-------------Config nova service -----------------------------

mkdir -p $OPENSTACK_DIR

cp -a /var/lib/nova $OPENSTACK_DIR/

chown -R nova:nova $OPENSTACK_DIR/nova
chown -R nova:nova /var/log/nova

test -f /etc/nova/nova.conf_bak ||cp -a /etc/nova/nova.conf /etc/nova/nova.conf_bak

sed -i '/^#/d' /etc/nova/nova.conf
sed -i '/^$/d' /etc/nova/nova.conf

openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $MASTER_IP
openstack-config --set /etc/nova/nova.conf DEFAULT log_dir /var/log/nova
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy  keystone
openstack-config --set /etc/nova/nova.conf DEFAULT multi_host True
openstack-config --set /etc/nova/nova.conf DEFAULT state_path $OPENSTACK_DIR/nova
openstack-config --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host true
openstack-config --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot true
openstack-config --set /etc/nova/nova.conf DEFAULT virt_type kvm

# rbd
openstack-config --set /etc/nova/nova.conf DEFAULT images_type rbd
openstack-config --set /etc/nova/nova.conf DEFAULT images_rbd_pool $VMS_POOL
openstack-config --set /etc/nova/nova.conf DEFAULT images_rbd_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/nova/nova.conf DEFAULT disk_cachemodes "network=writeback"
openstack-config --set /etc/nova/nova.conf DEFAULT rbd_user  cinder
openstack-config --set /etc/nova/nova.conf DEFAULT rbd_secret_uuid $RBD_UUID
openstack-config --set /etc/nova/nova.conf DEFAULT live_migration_flag "VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"

openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
openstack-config --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf DEFAULT running_deleted_instance_action reap
openstack-config --set /etc/nova/nova.conf DEFAULT multi_instance_display_name_template '%(name)s-%(count)s'
openstack-config --set /etc/nova/nova.conf DEFAULT scheduler_driver nova.scheduler.filter_scheduler.FilterScheduler
openstack-config --set /etc/nova/nova.conf DEFAULT max_instances_per_host 25
openstack-config --set /etc/nova/nova.conf DEFAULT console_allowed_origins $CONSOLE_URL
openstack-config --set /etc/nova/nova.conf DEFAULT vcpu_pin_set "8-39"

openstack-config --set /etc/nova/nova.conf DEFAULT scheduler_default_filters RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter,NumInstancesFilter
openstack-config --set /etc/nova/nova.conf DEFAULT cpu_allocation_ratio 3.0
openstack-config --set /etc/nova/nova.conf oslo_messaging_notifications driver nova.openstack.common.notifier.rpc_notifier
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

# Glance Port setting
openstack-config --set /etc/nova/nova.conf glance api_servers http://$VIP_NAME:9292

# Port setting
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen $HOSTNAME
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen_port 8774
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen $HOSTNAME
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen_port 8775

# logging
openstack-config --set /etc/nova/nova.conf DEFAULT debug False
openstack-config --set /etc/nova/nova.conf DEFAULT default_log_levels amqplib=WARN,sqlalchemy=WARN,boto=WARN,suds=INFO,qpid.messaging=INFO,iso8601.iso8601=INFO

# rabbit
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues True

# VNC
openstack-config --set /etc/nova/nova.conf vnc enabled true
openstack-config --set /etc/nova/nova.conf vnc keymap en-us
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://$VIP:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $MASTER_IP
openstack-config --set /etc/nova/nova.conf vnc novncproxy_host $MASTER_IP
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen $MASTER_IP

# Memcache
openstack-config --set /etc/nova/nova.conf DEFAULT memcached_servers "$MASTER_NAME_A:11211, $MASTER_NAME_B:11211"

# neutron
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron url http://$VIP_NAME:9696
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone
openstack-config --set /etc/nova/nova.conf neutron auth_url http://$VIP_NAME:5000/v3
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password $NEUTRON_USER_PWD
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy False
openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT force_config_drive true
openstack-config --set /etc/nova/nova.conf DEFAULT config_drive_skip_versions 
openstack-config --set /etc/nova/nova.conf hyperv config_drive_cdrom true
openstack-config --set /etc/nova/nova.conf hyperv config_drive_inject_password true
openstack-config --set /etc/nova/nova.conf DEFAULT flat_injected True

# database
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://$NOVA_DB_USER:$NOVA_DB_PWD@mysqlserver:$NOVA_DB_PORT/$NOVA_DB_NAME
openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://$NOVAAPI_DB_USER:$NOVAAPI_DB_PWD@mysqlserver:$NOVAAPI_DB_PORT/$NOVAAPI_DB_NAME
openstack-config --set /etc/nova/nova.conf database max_pool_size 100
openstack-config --set /etc/nova/nova.conf database max_overflow 200
openstack-config --set /etc/nova/nova.conf api_database max_pool_size 100
openstack-config --set /etc/nova/nova.conf api_database max_overflow 200

# keystone_authtoken
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password $NOVA_USER_PWD
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000/v3
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url  http://$VIP_NAME:35357/v3


cp -a /etc/nova/api-paste.ini /etc/nova/api-paste.ini_bak


#-------------Add nova user ssh -----------------------------------
usermod -d /var/lib/nova -s /bin/bash nova

rm -rf /var/lib/nova/.ssh
cp -av ../ssh /var/lib/nova/.ssh
chown -R nova:nova /var/lib/nova/.ssh
chmod 600 /var/lib/nova/.ssh/authorized_keys
chmod 600 /var/lib/nova/.ssh/id_rsa.pub
chmod 600 /var/lib/nova/.ssh/id_rsa


if [ -n "$MASTER_NAME" ]; then
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
fi
sleep 5

systemctl enable openstack-nova-api.service \
openstack-nova-consoleauth.service openstack-nova-scheduler.service \
openstack-nova-conductor.service openstack-nova-novncproxy.service

systemctl restart openstack-nova-api.service \
openstack-nova-consoleauth.service openstack-nova-scheduler.service \
openstack-nova-conductor.service openstack-nova-novncproxy.service
