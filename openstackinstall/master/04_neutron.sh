#!/bin/bash

source ./master.conf

# YUM rpm
rpm -ivh $OPENSTACK_REPO

# yum -y install openstack-neutron openstack-neutron-ml2 python-neutronclient
# yum -y install openstack-neutron-openvswitch

MASTER_NAME=`echo $HOSTNAME | grep 201`

#if [ -n "$MASTER_NAME" ]; then
#-------------Config Neutron service -----------------------------
#keystone user-create --name=neutron --pass=$NEUTRON_USER_PWD --email=neutron@chensh.net
#keystone user-role-add --user=neutron --tenant=service --role=admin
#keystone service-create --name=neutron --type=network --description="Neutron Network Service"
#sleep 1
#-------------Define Services and API Endpoints ---------------
#neutron
#neutron_service=$(keystone service-list | awk '/neutron/ {print $2}')
#keystone endpoint-create --service-id=$neutron_service --publicurl=http://$VIP_NAME:9696/ --internalurl=http://$VIP_NAME:9696/ --adminurl=http://$VIP_NAME:9696/

#fi

NOVA_TENANT_ID=`keystone tenant-list | grep service | awk '{print $2}'`

echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"

#-------------Config neutron service -----------------------------

cp -a /etc/neutron/neutron.conf /etc/neutron/neutron.conf_bak

sed -i '/^#/d' /etc/neutron/neutron.conf
sed -i '/^$/d' /etc/neutron/neutron.conf

NOVA_TENANT_ID=`keystone tenant-list | grep service | awk '{print $2}'`

openstack-config --set /etc/neutron/neutron.conf DEFAULT verbose True
openstack-config --set /etc/neutron/neutron.conf DEFAULT debug False
openstack-config --set /etc/neutron/neutron.conf DEFAULT use_syslog False
openstack-config --set /etc/neutron/neutron.conf DEFAULT log_dir /var/log/neutron
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host $HOSTNAME
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_port 9696
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins neutron.services.l3_router.l3_router_plugin.L3RouterPlugin
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

openstack-config --set /etc/neutron/neutron.conf DEFAULT api_workers $(grep -c ^processor /proc/cpuinfo)
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_workers $(grep -c ^processor /proc/cpuinfo)
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_agent_notification False

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True

openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_url http://$VIP_NAME:8774/v2

openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_username nova
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_tenant_id $NOVA_TENANT_ID
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_password $NOVA_USER_PWD
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_auth_url http://$VIP_NAME:35357/v2.0
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

openstack-config --set /etc/neutron/neutron.conf quotas quota_port 2000
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

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

# Delete
openstack-config --del /usr/share/neutron/neutron-dist.conf DEFAULT notification_driver

#-------------Config openvswitch -----------------------------
mkdir -p /var/log/openvswitch
touch /var/log/openvswitch/ovs-ctl.log

# delete default net
virsh net-destroy default
virsh net-undefine default

service openvswitch restart
service openvswitch restart
ovs-vsctl add-br br-int
ovs-vsctl add-br $NODE_PUB_NIC
ovs-vsctl add-port $NODE_PUB_NIC $PHY_PUB_NIC
#ovs-vsctl add-port $NODE_PUB_NIC $PHY_PUB_NIC lacp=active

#-------------Config service -----------------------------
chkconfig openvswitch on
chkconfig neutron-server on
service neutron-server restart

