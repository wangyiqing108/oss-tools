#!/bin/bash

source ./master.conf

# YUM rpm
rpm -ivh $OPENSTACK_REPO

MASTER_NAME=`echo $HOSTNAME | grep 244`


NOVA_TENANT_ID=`keystone tenant-list | grep service | awk '{print $2}'`

echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"

#-------------Config neutron service -----------------------------

NOVA_TENANT_ID=`keystone tenant-list | grep service | awk '{print $2}'`

cp -a /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini_bak

sed -i '/^#/d' /etc/neutron/l3_agent.ini
sed -i '/^$/d' /etc/neutron/l3_agent.ini

# controller node
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
#openstack-config --set /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy true
#openstack-config --set /etc/nova/nova.conf DEFAULT neutron_metadata_proxy_shared_secret METADATA_SECRET

# network node
# config L3
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT verbose True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT debug False
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT use_namespaces True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge 
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT gateway_external_network_id 
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT use_floatingip_qos True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT physical_external_nic eth3

# config DHCP
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT verbose True
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT debug False
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
##openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT use_namespaces True
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_delete_namespaces True
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dnsmasq_config_file /etc/neutron/dnsmasq-neutron.conf
#echo 'dhcp-option-force=26,1454' > /etc/neutron/dnsmasq-neutron.conf 
#killall dnsmasq

# config metadata agent
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT verbose True
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT debug False
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_url  http://c-84-26-dev01-jxq.bj-cn.vps.letv.cn:5000
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name service
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_user neutron
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_password E7ec7f48n7Bfa6q
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip c-84-26-dev01-jxq.bj-cn.vps.letv.cn
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret METADATA_SECRET

# config firewall
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent

service openstack-nova-api restart
service openstack-nova-scheduler restart
service openstack-nova-conductor restart
service neutron-server restart

service neutron-openvswitch-agent start
service neutron-l3-agent start
#service neutron-dhcp-agent start
#service neutron-metadata-agent start
chkconfig neutron-openvswitch-agent on
chkconfig neutron-l3-agent on
#chkconfig neutron-dhcp-agent on
#chkconfig neutron-metadata-agent on
