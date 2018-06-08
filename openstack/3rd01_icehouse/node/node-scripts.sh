#!/bin/bash

# YUM rpm

# file
source ./node.conf


# Default 
VLXLAN_IP=`ifconfig bond1 | grep "inet" | awk 'NR==1 {print $2}' | cut -d ":" -f 2`
MY_IP=`ifconfig $NODE_MANAGE_NIC | grep "inet" | awk 'NR==1 {print $2}' | cut -d ":" -f 2`

#-------------Clear Hosts Config----------------------------

echo "-------------------Close Network Security---------------------"

echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"
systemctl stop iptables
systemctl disable iptables
#-------------Config nova service -----------------------------

mkdir -p $OPENSTACK_DIR

cp -a /var/lib/nova $OPENSTACK_DIR/

test -f /etc/nova/nova.conf_bak || cp -a /etc/nova/nova.conf /etc/nova/nova.conf_bak

sed -i '/^#/d' /etc/nova/nova.conf
sed -i '/^$/d' /etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $MY_IP
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy  keystone
openstack-config --set /etc/nova/nova.conf DEFAULT multi_host True
openstack-config --set /etc/nova/nova.conf DEFAULT state_path $OPENSTACK_DIR/nova
openstack-config --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host true
openstack-config --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot true

openstack-config --set /etc/nova/nova.conf libvirt images_type rbd
openstack-config --set /etc/nova/nova.conf libvirt images_rbd_pool $VMS_POOL
openstack-config --set /etc/nova/nova.conf libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/nova/nova.conf libvirt rbd_user cinder
openstack-config --set /etc/nova/nova.conf libvirt rbd_secret_uuid 457eb676-33da-42ec-9a8c-9293d545c337
openstack-config --set /etc/nova/nova.conf libvirt cpu_mode host-model
openstack-config --set /etc/nova/nova.conf libvirt type kvm
openstack-config --set /etc/nova/nova.conf libvirt inject_key  false
openstack-config --set /etc/nova/nova.conf libvirt inject_password  false
openstack-config --set /etc/nova/nova.conf libvirt inject_partition  -2
openstack-config --set /etc/nova/nova.conf libvirt live_migration_flag  VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST

openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
openstack-config --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf DEFAULT running_deleted_instance_action reap
openstack-config --set /etc/nova/nova.conf DEFAULT scheduler_driver nova.scheduler.filter_scheduler.FilterScheduler
openstack-config --set /etc/nova/nova.conf oslo_messaging_notifications driver nova.openstack.common.notifier.rpc_notifier

# Glance Port setting
openstack-config --set /etc/nova/nova.conf glance api_servers http://$MASTER_NAME:9292

# logging
openstack-config --set /etc/nova/nova.conf DEFAULT debug False
openstack-config --set /etc/nova/nova.conf DEFAULT default_log_levels amqplib=WARN,sqlalchemy=WARN,boto=WARN,suds=INFO,qpid.messaging=INFO,iso8601.iso8601=INFO

# rabbitmq
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues True

# VNC
openstack-config --set /etc/nova/nova.conf vnc enabled true
openstack-config --set /etc/nova/nova.conf vnc keymap en-us
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://$MASTER_IP:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $MY_IP
openstack-config --set /etc/nova/nova.conf vnc novncproxy_host $MY_IP
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen $MY_IP

# neutron
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron url http://$MASTER_NAME:9696
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service
openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone
openstack-config --set /etc/nova/nova.conf neutron auth_url http://$MASTER_NAME:5000/v3
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
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
# database
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://$NOVA_DB_USER:$NOVA_DB_PWD@mysqlserver:$NOVA_DB_PORT/$NOVA_DB_NAME
openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://$NOVAAPI_DB_USER:$NOVAAPI_DB_PWD@mysqlserver:$NOVAAPI_DB_PORT/$NOVAAPI_DB_NAME
openstack-config --set /etc/nova/nova.conf database max_pool_size 5
openstack-config --set /etc/nova/nova.conf database max_overflow 15
openstack-config --set /etc/nova/nova.conf api_database max_pool_size 5
openstack-config --set /etc/nova/nova.conf api_database max_overflow 15
openstack-config --set /etc/nova/nova.conf DEFAULT vcpu_pin_set "8-39" 

# keystone_authtoken
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password $NOVA_USER_PWD
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri  http://$MASTER_NAME:5000/v3
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url  http://$MASTER_NAME:35357/v3

#-------------Config neutron service -----------------------------

test -f /etc/neutron/neutron.conf_bak || cp -a /etc/neutron/neutron.conf /etc/neutron/neutron.conf_bak

sed -i '/^#/d' /etc/neutron/neutron.conf
sed -i '/^$/d' /etc/neutron/neutron.conf

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

# rabbitmq
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues True

openstack-config --set /etc/neutron/neutron.conf DEFAULT agent_down_time 75
openstack-config --set /etc/neutron/neutron.conf DEFAULT api_workers 0

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True

# nova
openstack-config --set /etc/neutron/neutron.conf nova url http://$MASTER_NAME:8774/v2.1
openstack-config --set /etc/neutron/neutron.conf nova auth_url http://$MASTER_NAME:35357/v3
openstack-config --set /etc/neutron/neutron.conf nova auth_type password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password $NOVA_USER_PWD
openstack-config --set /etc/neutron/neutron.conf DEFAULT send_events_interval 2

# keystone_authtoken
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_USER_PWD
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri  http://$MASTER_NAME:5000/v3
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url  http://$MASTER_NAME:35357/v3

# database
openstack-config --set /etc/neutron/neutron.conf database connection  mysql+pymysql://$NEUTRON_DB_USER:$NEUTRON_DB_PWD@mysqlserver:$NEUTRON_DB_PORT/$NEUTRON_DB_NAME
openstack-config --set /etc/neutron/neutron.conf database max_pool_size 5
openstack-config --set /etc/neutron/neutron.conf database max_overflow 10


#-------------Config ml2_conf service -----------------------------

test -f /etc/neutron/plugins/ml2/openvswitch_agent.ini_bak || cp -a /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini_bak
test -f /etc/neutron/plugins/ml2/ml2.ini_bak || cp -a /etc/neutron/plugins/ml2/ml2.ini /etc/neutron/plugins/ml2/ml2.ini_bak

sed -i '/^#/d' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^$/d' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^#/d' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^$/d' /etc/neutron/plugins/ml2/ml2_conf.ini

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
ln -fs plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron

# config metadata
#openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy true
#openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret METADATA_SECRET


#-------------Config openvswitch -----------------------------
service openvswitch start
systemctl restart libvirtd 

#-------------Config Ceph -------------------------------
cd /root
cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
        <uuid>457eb676-33da-42ec-9a8c-9293d545c337</uuid>
        <usage type='ceph'>
                <name>client.cinder secret</name>
        </usage>
</secret>
EOF
sudo virsh secret-define --file secret.xml
sleep 1
ceph auth get-key client.cinder|tee client.cinder.key
sleep 1
sudo virsh secret-set-value --secret 457eb676-33da-42ec-9a8c-9293d545c337 --base64 $(cat client.cinder.key) 

# live migate
sed -i 's/#listen_tls = 0/listen_tls = 0/g' /etc/libvirt/libvirtd.conf
sed -i 's/#listen_tcp = 1/listen_tcp = 1/g' /etc/libvirt/libvirtd.conf
sed -i 's/#tcp_port = "16509"/tcp_port = "16509"/g' /etc/libvirt/libvirtd.conf
sed -i 's/#listen_addr = "192.168.0.1"/listen_addr = "0.0.0.0"/g' /etc/libvirt/libvirtd.conf
sed -i 's/#listen_addr = "0.0.0.0"/listen_addr = "0.0.0.0"/g' /etc/libvirt/libvirtd.conf
sed -i 's/#auth_tcp = "sasl"/auth_tcp = "none"/g' /etc/libvirt/libvirtd.conf 
sed -i 's/#LIBVIRTD_ARGS="-listen"/LIBVIRTD_ARGS="-listen"/g' /etc/libvirt/libvirtd.conf
sed -i 's/#LIBVIRTD_ARGS="--listen"/LIBVIRTD_ARGS="--listen"/g' /etc/sysconfig/libvirtd 
systemctl restart libvirtd openstack-nova-compute

#-------------Config ceilometer service -----------------------------

test -f /etc/ceilometer/ceilometer.conf_bak || cp -a /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf_bak
sed -i '/^#/d' /etc/ceilometer/ceilometer.conf
sed -i '/^$/d' /etc/ceilometer/ceilometer.conf

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_ha_queues True

# keystone_authtoken
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_type password
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_name service
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken username ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken password $CEILOMETER_USER_PWD
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri  http://$MASTER_NAME:5000/v3
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_url  http://$MASTER_NAME:35357/v3

sed -i "s/notifier:\/\//udp:\/\/${CEILOMETER_UDP_SERVER}:4952/g" /etc/ceilometer/pipeline.yaml
sed -i "s/interval: 600/interval: 60/g" /etc/ceilometer/pipeline.yaml
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_url http://$MASTER_NAME:5000/v3
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials username ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_name service
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials password $CEILOMETER_USER_PWD
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials user_domain_name default
#-------------Config service -----------------------------
systemctl enable libvirtd openvswitch openstack-nova-compute neutron-openvswitch-agent openstack-ceilometer-compute
systemctl restart libvirtd openvswitch openstack-nova-compute neutron-openvswitch-agent openstack-ceilometer-compute

#-------------Add nova user ssh -----------------------------------
usermod -d /var/lib/nova -s /bin/bash nova

sed -i 's/install nf_conntrack/#install nf_conntrack/g' /etc/modprobe.d/nf_conntrack.conf 

rm -rf /var/lib/nova/.ssh
cp -av ../ssh /var/lib/nova/.ssh
chown -R nova:nova /var/lib/nova/.ssh
chmod 600 /var/lib/nova/.ssh/authorized_keys
chmod 600 /var/lib/nova/.ssh/id_rsa.pub
chmod 600 /var/lib/nova/.ssh/id_rsa

openstack-status

ethtool -N eth2 rx-flow-hash udp4 sdfn 
ethtool -N eth3 rx-flow-hash udp4 sdfn 
