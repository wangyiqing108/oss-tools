#!/bin/bash

source ./master.conf

MASTER_NAME=`echo $HOSTNAME | grep 201`

NOVA_TENANT_ID=`openstack project list | grep service | awk '{print $2}'`
VLXLAN_IP=`ifconfig bond1 | grep "inet" | awk 'NR==1 {print $2}' | cut -d ":" -f 2`
echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"

#-------------Config neutron service -----------------------------

test -f /etc/neutron/l3_agent.ini_bak || cp -a /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini_bak
sed -i '/^#/d' /etc/neutron/l3_agent.ini
sed -i '/^$/d' /etc/neutron/l3_agent.ini
sed -i '/^#/d' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^$/d' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^#/d' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^$/d' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^#/d' /etc/neutron/metering_agent.ini 
sed -i '/^$/d' /etc/neutron/metering_agent.ini 
sed -i 's/^install nf_conntrack/^#^install nf_conntrack/g' /etc/modprobe.d/nf_conntrack.conf 
openstack-config --set /etc/neutron/neutron.conf DEFAULT debug False
openstack-config --set /etc/neutron/neutron.conf DEFAULT use_syslog False
openstack-config --set /etc/neutron/neutron.conf DEFAULT log_dir /var/log/neutron
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host $HOSTNAME
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_port 9696
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router,metering
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT base_mac $VM_MAC
openstack-config --set /etc/neutron/neutron.conf DEFAULT mac_generation_retries 16
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_lease_duration 86400
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_bulk True
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_pagination False
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_sorting False
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notification_driver neutron.openstack.common.notifier.rpc_notifier
# rabbitmq
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues True

openstack-config --set /etc/neutron/neutron.conf DEFAULT agent_down_time 75
openstack-config --set /etc/neutron/neutron.conf DEFAULT api_workers $(grep -c ^processor /proc/cpuinfo)
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_workers $(grep -c ^processor /proc/cpuinfo)

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True

# nova
openstack-config --set /etc/neutron/neutron.conf nova url http://$VIP_NAME:8774/v2.1
openstack-config --set /etc/neutron/neutron.conf nova auth_url http://$VIP_NAME:35357/v3
openstack-config --set /etc/neutron/neutron.conf nova auth_type password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password $NOVA_USER_PWD 
openstack-config --set /etc/neutron/neutron.conf nova project_id $NOVA_TENANT_ID

openstack-config --set /etc/neutron/neutron.conf DEFAULT send_events_interval 2
# config L3 HA
openstack-config --set /etc/neutron/neutron.conf DEFAULT l3_ha True
openstack-config --set /etc/neutron/neutron.conf DEFAULT max_l3_agents_per_router 2
openstack-config --set /etc/neutron/neutron.conf DEFAULT min_l3_agents_per_router 2
openstack-config --set /etc/neutron/neutron.conf DEFAULT l3_ha_net_cidr 169.254.192.0/18
#openstack-config --set /etc/neutron/neutron.conf DEFAULT delete_ha_network_if_no_remain_ha_router True

openstack-config --set /etc/neutron/neutron.conf DEFAULT enable_fip_rate_limit True
openstack-config --set /etc/neutron/neutron.conf DEFAULT fip_rate_limit_default_rate 1
openstack-config --set /etc/neutron/neutron.conf DEFAULT enable_gateway_rate_limit True
openstack-config --set /etc/neutron/neutron.conf DEFAULT gateway_rate_limit_default_rate 1
openstack-config --set /etc/neutron/neutron.conf DEFAULT enable_l3_metering True
# L3 AZ
openstack-config --set /etc/neutron/neutron.conf DEFAULT router_scheduler_driver neutron.scheduler.l3_agent_scheduler.AZLeastRoutersScheduler
openstack-config --set /etc/neutron/neutron.conf DEFAULT default_availability_zones az1,az2

#openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_bond_fip_to_router_gateway True
openstack-config --set /etc/neutron/neutron.conf agent check_child_processes_interval 30
openstack-config --set /etc/neutron/neutron.conf agent check_child_processes_action respawn
# keystone_authtoken
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_USER_PWD
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000/v3
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url  http://$VIP_NAME:35357/v3
# database
openstack-config --set /etc/neutron/neutron.conf database connection  mysql+pymysql://$NEUTRON_DB_USER:$NEUTRON_DB_PWD@mysqlserver:$NEUTRON_DB_PORT/$NEUTRON_DB_NAME
openstack-config --set /etc/neutron/neutron.conf database max_pool_size 150
openstack-config --set /etc/neutron/neutron.conf database max_overflow 300
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

# config L3
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT debug False
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge 
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT enable_metadata_proxy False
# VRRP advertisement interval
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT ha_vrrp_advert_int 2
openstack-config --set /etc/neutron/l3_agent.ini AGENT availability_zone $AZ
# config L3 floating ip QoS
# neutron bond fip to router gateway
#openstack-config --set /etc/neutron/l3_agent.ini DEFAULT fip_use_public_subnet_cidr False

# config L3 floating ip QoS
#openstack-config --set /etc/neutron/l3_agent.ini DEFAULT use_floatingip_qos True
#openstack-config --set /etc/neutron/l3_agent.ini DEFAULT fip_tc_ingress_protocol 802.1q
#openstack-config --set /etc/neutron/l3_agent.ini DEFAULT fip_tc_ingress_offset 20
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
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT enable_metadata_proxy False
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT verbose True
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT debug False
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_url  http://c-84-26-dev01-jxq.bj-cn.vps.letv.cn:5000
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name service
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_user neutron
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_password E7ec7f48n7Bfa6q
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip c-84-26-dev01-jxq.bj-cn.vps.letv.cn
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret METADATA_SECRET


#-------------Config ml2_conf service -----------------------------

test -f /etc/neutron/plugins/ml2/openvswitch_agent.ini_bak || cp -a /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini_bak
test -f /etc/neutron/plugins/ml2/ml2.ini_bak || cp -a /etc/neutron/plugins/ml2/ml2.ini /etc/neutron/plugins/ml2/ml2.ini_bak


openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1000:50000

# config securitygroup
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population true
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent arp_responder true
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent prevent_arp_spoofing true
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $VLXLAN_IP
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings external:br-ex 
ln -fs plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini


#-------------Config Metering---------------------------------
openstack-config --set  /etc/neutron/metering_agent.ini DEFAULT debug False
openstack-config --set  /etc/neutron/metering_agent.ini DEFAULT driver neutron.services.metering.drivers.iptables.iptables_driver.IptablesMeteringDriver
openstack-config --set  /etc/neutron/metering_agent.ini DEFAULT measure_interval 60
openstack-config --set  /etc/neutron/metering_agent.ini DEFAULT report_interval 300
openstack-config --set  /etc/neutron/metering_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set  /etc/neutron/metering_agent.ini DEFAULT use_namespaces True
openstack-config --set  /etc/neutron/metering_agent.ini DEFAULT enable_udp_publisher True
openstack-config --set  /etc/neutron/metering_agent.ini DEFAULT sample_source openstack
openstack-config --set  /etc/neutron/metering_agent.ini publisher udp_address $CEILOMETER_UDP_SERVER
openstack-config --set  /etc/neutron/metering_agent.ini publisher udp_port 4952
openstack-config --set  /etc/neutron/metering_agent.ini publisher shrink_metadata True

#-------------Config openvswitch -----------------------------
mkdir -p /var/log/openvswitch
touch /var/log/openvswitch/ovs-ctl.log

systemctl restart openvswitch
systemctl restart openvswitch

ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex bond2

systemctl enable neutron-l3-agent.service neutron-openvswitch-agent.service neutron-metering-agent.service openvswitch
systemctl restart neutron-l3-agent.service neutron-openvswitch-agent.service neutron-metering-agent.service  openvswitch

ethtool -N eth0 rx-flow-hash udp4 sdfn 
ethtool -N eth1 rx-flow-hash udp4 sdfn 
ethtool -N eth2 rx-flow-hash udp4 sdfn 
ethtool -N eth3 rx-flow-hash udp4 sdfn 
