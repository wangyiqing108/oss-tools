#!/bin/bash

# YUM rpm

#rpm -ivh $OPENSTACK_REPO

sleep 1

#yum -y install openstack-utils openstack-nova-compute openstack-neutron-ml2 openstack-neutron-openvswitch

# file
source ./master.conf


# Default 

#MY_IP=`ifconfig $NODE_MANAGE_NIC | grep "inet addr" | awk 'NR==1 {print $2}' | cut -d ":" -f 2`
MY_IP=`more /etc/hosts | grep $HOSTNAME | awk '{print $1}'`

#-------------Clear Hosts Config----------------------------

#NEW_HOSTS="/etc/hosts"

#sed -i "/localhost/! d" $NEW_HOSTS

#cat /root/install/host.conf >> $NEW_HOSTS

echo "-------------------Close Network Security---------------------"

sed -i "7s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config > /dev/null

sed -i "2s/^install/#install/" /etc/modprobe.d/nf_conntrack.conf > /dev/null

sed -i "s/net.ipv4.conf.default.rp_filter = 2/net.ipv4.conf.default.rp_filter = 0/" /etc/sysctl.conf > /dev/null
sed -i "s/net.ipv4.conf.all.rp_filter = 2/net.ipv4.conf.all.rp_filter = 0/" /etc/sysctl.conf > /dev/null

sysctl -p

service iptables stop > /dev/null
service ip6tables stop > /dev/null

chkconfig  iptables off 
chkconfig  ip6tables off

echo "-------------------Config grub.conf---------------------------"

sed -i "11s/timeout=5/timeout=0/" /boot/grub/grub.conf 

echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"

#-------------Config nova service -----------------------------

mkdir -p $OPENSTACK_DIR

cp -a /var/lib/nova $OPENSTACK_DIR/

cp -a /etc/nova/nova.conf /etc/nova/nova.conf_bak

sed -i '/^#/d' /etc/nova/nova.conf
sed -i '/^$/d' /etc/nova/nova.conf

openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $MY_IP
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy  keystone
openstack-config --set /etc/nova/nova.conf DEFAULT multi_host True
openstack-config --set /etc/nova/nova.conf DEFAULT state_path $OPENSTACK_DIR/nova
openstack-config --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host true
openstack-config --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot true
openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_cpu_mode host-model
openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_type kvm
openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
openstack-config --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf DEFAULT running_deleted_instance_action reap
openstack-config --set /etc/nova/nova.conf DEFAULT scheduler_driver nova.scheduler.filter_scheduler.FilterScheduler
openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_vif_driver nova.virt.libvirt.vif.LibvirtGenericVIFDriver
openstack-config --set /etc/nova/nova.conf DEFAULT notification_driver nova.openstack.common.notifier.rpc_notifier

# Glance Port setting
openstack-config --set /etc/nova/nova.conf DEFAULT glance_api_servers $VIP_NAME:9292

# logging
openstack-config --set /etc/nova/nova.conf DEFAULT debug False
openstack-config --set /etc/nova/nova.conf DEFAULT verbose True
openstack-config --set /etc/nova/nova.conf DEFAULT default_log_levels amqplib=WARN,sqlalchemy=WARN,boto=WARN,suds=INFO,qpid.messaging=INFO,iso8601.iso8601=INFO

# qpid
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_hosts "$MASTER_NAME_A:5672, $MASTER_NAME_B:5672"
openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_userid $RABBIT_USERID
openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_ha_queues True

# VNC
openstack-config --set /etc/nova/nova.conf DEFAULT vnc_enabled true
openstack-config --set /etc/nova/nova.conf DEFAULT vnc_keymap en-us
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://$VIP:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $MY_IP
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_host $MY_IP
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen $MY_IP

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

# keystone_authtoken
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host $VIP_NAME
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password $NOVA_USER_PWD

#-------------Config neutron service -----------------------------

cp -a /etc/neutron/neutron.conf /etc/neutron/neutron.conf_bak

sed -i '/^#/d' /etc/neutron/neutron.conf
sed -i '/^$/d' /etc/neutron/neutron.conf

openstack-config --set /etc/neutron/neutron.conf DEFAULT verbose True
openstack-config --set /etc/neutron/neutron.conf DEFAULT debug False
openstack-config --set /etc/neutron/neutron.conf DEFAULT use_syslog False
openstack-config --set /etc/neutron/neutron.conf DEFAULT log_dir /var/log/neutron
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host $HOSTNAME
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_port 9696
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT base_mac $VM_MAC
openstack-config --set /etc/neutron/neutron.conf DEFAULT mac_generation_retries 16
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_lease_duration 86400
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_bulk True
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_pagination False
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_sorting False
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

# QPID
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_kombu

openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_hosts "$MASTER_NAME_A:5672, $MASTER_NAME_B:5672"

openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_userid $RABBIT_USERID
openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_ha_queues True

openstack-config --set /etc/neutron/neutron.conf DEFAULT agent_down_time 75
openstack-config --set /etc/neutron/neutron.conf DEFAULT api_workers 0

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True

openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_url http://$VIP_NAME:8774/v2

openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_username nova
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_password $NOVA_USER_PWD

openstack-config --set /etc/neutron/neutron.conf DEFAULT neutron_admin_auth_url http://$VIP_NAME:5000/v2.0
openstack-config --set /etc/neutron/neutron.conf DEFAULT send_events_interval 2

# keystone_authtoken
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$VIP_NAME:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken identity_uri http://$VIP_NAME:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host $VIP_NAME
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $NEUTRON_USER_PWD

# database
openstack-config --set /etc/neutron/neutron.conf database connection mysql://$NEUTRON_DB_USER:$NEUTRON_DB_PWD@mysqlserver:$NEUTRON_DB_PORT/$NEUTRON_DB_NAME

#-------------Config ml2_conf service -----------------------------

cp -a /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini_bak

sed -i '/^#/d' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^$/d' /etc/neutron/plugins/ml2/ml2_conf.ini

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers vlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch


openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks physnet-ex


openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges physnet$PLUGIN_ID:1:4000

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group False
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver


openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings physnet$PLUGIN_ID:$NODE_PUB_NIC

ln -s plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

#mv /usr/lib/python2.6/site-packages/qpid/messaging/driver.py /usr/lib/python2.6/site-packages/qpid/messaging/driver.py_bak
#wget -P /usr/lib/python2.6/site-packages/qpid/messaging http://openstack.oss.letv.cn:8080/Tools/qpid/driver.py

#-------------Config openvswitch -----------------------------
service openvswitch start
service openvswitch start
ovs-vsctl add-br br-int
ovs-vsctl add-br $NODE_PUB_NIC
ovs-vsctl add-port $NODE_PUB_NIC $PHY_PUB_NIC

#-------------Config service -----------------------------
chkconfig libvirtd on
chkconfig messagebus on
chkconfig openvswitch on
chkconfig openstack-nova-compute on
chkconfig neutron-openvswitch-agent on

service libvirtd restart
service messagebus restart
service openvswitch restart
service openstack-nova-compute restart
service neutron-openvswitch-agent restart

#-------------Add nova user ssh -----------------------------------
usermod -d /var/lib/nova -s /bin/bash nova

rm -rf /var/lib/nova/.ssh
cp -av ../ssh /var/lib/nova/.ssh
chown -R nova:nova /var/lib/nova/.ssh
chmod 600 /var/lib/nova/.ssh/authorized_keys
chmod 600 /var/lib/nova/.ssh/id_rsa.pub

openstack-status

