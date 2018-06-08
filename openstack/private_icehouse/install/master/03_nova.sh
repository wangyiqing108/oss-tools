#!/bin/bash
# yum -y install openstack-dashboard python-django-horizon

source ./master.conf

# yum rpm
rpm -ivh $OPENSTACK_REPO

# yum -y install openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler

MASTER_NAME=`echo $HOSTNAME | grep 201`
MASTER_IP=`more /etc/hosts | grep $HOSTNAME | awk '{print $1}'`

#if [ -n "$MASTER_NAME" ]; then

#-------------Config Nova service -----------------------------

#keystone user-create --name=nova --pass=$NOVA_USER_PWD --email=nova@chensh.net

#keystone user-role-add --user=nova --tenant=service --role=admin

#keystone service-create --name=nova --type=compute --description="Nova Compute Service"
#sleep 1
#-------------Define Services and API Endpoints ---------------
#Nova
#nova_service=$(keystone service-list | awk '/nova/ {print $2}')
#keystone endpoint-create --service-id=$nova_service --publicurl=http://$VIP_NAME:8774/v2/%\(tenant_id\)s --internalurl=http://$VIP_NAME:8774/v2/%\(tenant_id\)s --adminurl=http://$VIP_NAME:8774/v2/%\(tenant_id\)s
#sleep 1

#fi

echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"

#-------------Config nova service -----------------------------

mkdir -p $OPENSTACK_DIR

cp -a /var/lib/nova $OPENSTACK_DIR/

chown -R nova:nova $OPENSTACK_DIR/nova
chown -R nova:nova /var/log/nova

cp -a /etc/nova/nova.conf /etc/nova/nova.conf_bak

sed -i '/^#/d' /etc/nova/nova.conf
sed -i '/^$/d' /etc/nova/nova.conf

openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $MASTER_IP
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy  keystone
openstack-config --set /etc/nova/nova.conf DEFAULT multi_host True
openstack-config --set /etc/nova/nova.conf DEFAULT state_path $OPENSTACK_DIR/nova
openstack-config --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host true
openstack-config --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot true
#host-passthrough 会导致老版本的qemu 虚拟机重启
#openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_cpu_mode host-passthrough
openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_type kvm
openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
openstack-config --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf DEFAULT running_deleted_instance_action reap
openstack-config --set /etc/nova/nova.conf DEFAULT multi_instance_display_name_template '%(name)s-%(count)s'
openstack-config --set /etc/nova/nova.conf DEFAULT scheduler_driver nova.scheduler.filter_scheduler.FilterScheduler
openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_vif_driver nova.virt.libvirt.vif.LibvirtGenericVIFDriver
openstack-config --set /etc/nova/nova.conf DEFAULT notification_driver nova.openstack.common.notifier.rpc_notifier
openstack-config --set /etc/nova/nova.conf DEFAULT max_instances_per_host 8
openstack-config --set /etc/nova/nova.conf DEFAULT scheduler_default_filters RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter,NumInstancesFilter
#配额和超分比
openstack-config --set /etc/nova/nova.conf DEFAULT quota_instances 1600
openstack-config --set /etc/nova/nova.conf DEFAULT quota_cores 25600
openstack-config --set /etc/nova/nova.conf DEFAULT quota_ram 13107200
openstack-config --set /etc/nova/nova.conf DEFAULT cpu_allocation_ratio 4.0
openstack-config --set /etc/nova/nova.conf DEFAULT ram_allocation_ratio 1.5
openstack-config --set /etc/nova/nova.conf DEFAULT reserved_host_memory_mb 512
openstack-config --set /etc/nova/nova.conf DEFAULT reserved_host_disk_mb 1024
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_max_limit 3000
# Glance Port setting
openstack-config --set /etc/nova/nova.conf DEFAULT glance_api_servers $VIP_NAME:9292
#Port setting
openstack-config --set /etc/nova/nova.conf DEFAULT ec2_listen $HOSTNAME
openstack-config --set /etc/nova/nova.conf DEFAULT ec2_listen_port 8773
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen $HOSTNAME
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen_port 8774
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen $HOSTNAME
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen_port 8775

# logging
openstack-config --set /etc/nova/nova.conf DEFAULT debug False
openstack-config --set /etc/nova/nova.conf DEFAULT verbose True
openstack-config --set /etc/nova/nova.conf DEFAULT default_log_levels amqplib=WARN,sqlalchemy=WARN,boto=WARN,suds=INFO,qpid.messaging=INFO,iso8601.iso8601=INFO

# rabbit
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_hosts "$MASTER_NAME_A:5672, $MASTER_NAME_B:5672"
openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_userid $RABBIT_USERID
openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_ha_queues True
openstack-config --del /etc/nova/nova.conf DEFAULT notification_driver

# VNC
openstack-config --set /etc/nova/nova.conf DEFAULT vnc_enabled true
openstack-config --set /etc/nova/nova.conf DEFAULT vnc_keymap en-us
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://$VIP:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $MASTER_IP
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_host $MASTER_IP
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen $MASTER_IP

#Memcache
openstack-config --set /etc/nova/nova.conf DEFAULT memcached_servers "$MASTER_NAME_A:11211, $MASTER_NAME_B:11211"

# neutron
openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://$VIP_NAME:9696
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url http://$VIP_NAME:5000/v2.0
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username neutron
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password $NEUTRON_USER_PWD
openstack-config --set /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy False
openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api nova
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT force_config_drive always
openstack-config --set /etc/nova/nova.conf DEFAULT flat_injected True

# database
openstack-config --set /etc/nova/nova.conf database connection mysql://$NOVA_DB_USER:$NOVA_DB_PWD@mysqlserver:$NOVA_DB_PORT/$NOVA_DB_NAME
openstack-config --set /etc/nova/nova.conf database max_pool_size 5
openstack-config --set /etc/nova/nova.conf database max_overflow 15

# keystone_authtoken
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host $VIP_NAME
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password $NOVA_USER_PWD

cp -a /etc/nova/api-paste.ini /etc/nova/api-paste.ini_bak

openstack-config --set /etc/nova/api-paste.ini filter:authtoken auth_url http://$VIP_NAME:35357/v2.0
openstack-config --set /etc/nova/api-paste.ini filter:authtoken auth_host $VIP_NAME
openstack-config --set /etc/nova/api-paste.ini filter:authtoken auth_port 35357
openstack-config --set /etc/nova/api-paste.ini filter:authtoken auth_protocol http
openstack-config --set /etc/nova/api-paste.ini filter:authtoken admin_user nova
openstack-config --set /etc/nova/api-paste.ini filter:authtoken admin_tenant_name service
openstack-config --set /etc/nova/api-paste.ini filter:authtoken admin_password $NOVA_USER_PWD

cp -a /usr/lib/python2.6/site-packages/nova/api/manager.py /usr/lib/python2.6/site-packages/nova/api/manager.py.bak
sed -i "s/self.network_driver.metadata_accept()/#self.network_driver.metadata_accept()/" /usr/lib/python2.6/site-packages/nova/api/manager.py > /dev/null

#-------------Config service -----------------------------
chkconfig openstack-nova-api on
chkconfig openstack-nova-conductor on
chkconfig openstack-nova-consoleauth on
chkconfig openstack-nova-novncproxy on
chkconfig openstack-nova-scheduler on

#-------------Add nova user ssh -----------------------------------
usermod -d /var/lib/nova -s /bin/bash nova

rm -rf /var/lib/nova/.ssh
cp -av ../ssh /var/lib/nova/.ssh
chown -R nova:nova /var/lib/nova/.ssh
chmod 600 /var/lib/nova/.ssh/authorized_keys
chmod 600 /var/lib/nova/.ssh/id_rsa.pub
chmod 600 /var/lib/nova/.ssh/id_rsa


if [ -n "$MASTER_NAME" ]; then
nova-manage db sync
fi
sleep 5

service openstack-nova-api restart
service openstack-nova-conductor restart
service openstack-nova-consoleauth restart
service openstack-nova-novncproxy restart
service openstack-nova-scheduler restart

# echo "nova-manage db sync"

