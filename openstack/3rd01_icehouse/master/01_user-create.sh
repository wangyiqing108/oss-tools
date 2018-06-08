#!/bin/bash

source ./master.conf

#keystone:
openstack domain create --description "Default Domain" default
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password $ADMIN_PWD $ADMIN_USER
sleep 1
openstack role create admin
openstack role create Member
openstack role add --project admin --user admin admin
openstack project create --domain default  --description "Service Project" service

openstack service create --name keystone --description "OpenStack Identity" identity
sleep 1
openstack endpoint create --region RegionOne identity public http://$VIP_NAME:5000/v3
openstack endpoint create --region RegionOne identity internal http://$VIP_NAME:5000/v3
openstack endpoint create --region RegionOne identity admin http://$VIP_NAME:35357/v3

#glance:
openstack user create --domain default --password $GLANCE_USER_PWD glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
sleep 1
openstack endpoint create --region RegionOne image public http://$VIP_NAME:9292
openstack endpoint create --region RegionOne image internal http://$VIP_NAME:9292
openstack endpoint create --region RegionOne image admin http://$VIP_NAME:9292

#nova:
openstack user create --domain default --password $NOVA_USER_PWD nova
openstack role add --project service --user nova admin
openstack service create --name nova  --description "OpenStack Compute" compute
sleep 1
openstack endpoint create --region RegionOne  compute public http://$VIP_NAME:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  compute internal http://$VIP_NAME:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  compute admin http://$VIP_NAME:8774/v2.1/%\(tenant_id\)s

#neutron:
openstack user create --domain default --password $NEUTRON_USER_PWD neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
sleep 1
openstack endpoint create --region RegionOne  network public http://$VIP_NAME:9696
openstack endpoint create --region RegionOne  network internal http://$VIP_NAME:9696
openstack endpoint create --region RegionOne  network admin http://$VIP_NAME:9696

#cinder:
openstack user create --domain default --password $CINDER_USER_PWD cinder
openstack role add --project service --user cinder admin
openstack service create --name cinder  --description "OpenStack Block Storage" volume
openstack service create --name cinderv2  --description "OpenStack Block Storage" volumev2
sleep 1
openstack endpoint create --region RegionOne  volume public http://$VIP_NAME:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  volume internal http://$VIP_NAME:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  volume admin http://$VIP_NAME:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  volumev2 public http://$VIP_NAME:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne  volumev2 internal http://$VIP_NAME:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne  volumev2 admin http://$VIP_NAME:8776/v2/%\(tenant_id\)s

#ceilometer:
openstack user create --domain default --password $CEILOMETER_USER_PWD ceilometer
openstack role add --project service --user ceilometer admin
openstack service create --name ceilometer  --description "Telemetry" metering
sleep 1
openstack endpoint create --region RegionOne  metering public http://$VIP_NAME:8777
openstack endpoint create --region RegionOne  metering internal http://$VIP_NAME:8777
openstack endpoint create --region RegionOne  metering admin http://$VIP_NAME:8777

#aodh
openstack user create --domain default --password $AODH_USER_PWD aodh
openstack role add --project service --user aodh admin
openstack service create --name aodh  --description "Telemetry" alarming
sleep 1
openstack endpoint create --region RegionOne  alarming public http://$VIP_NAME:8042
openstack endpoint create --region RegionOne  alarming internal http://$VIP_NAME:8042 
openstack endpoint create --region RegionOne  alarming admin http://$VIP_NAME:8042

#heat:
openstack user create --domain default --password $HEAT_USER_PWD heat
openstack role add --project service --user heat admin
openstack service create --name heat --description "Orchestration" orchestration
openstack service create --name heat-cfn  --description "Orchestration"  cloudformation 
sleep 1
openstack endpoint create --region RegionOne  orchestration public http://$VIP_NAME:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  orchestration internal http://$VIP_NAME:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  orchestration admin http://$VIP_NAME:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  cloudformation public http://$VIP_NAME:8000/v1
openstack endpoint create --region RegionOne  cloudformation internal http://$VIP_NAME:8000/v1
openstack endpoint create --region RegionOne  cloudformation admin http://$VIP_NAME:8000/v1
openstack domain create --description "Stack projects and users" heat
openstack user create --domain heat --password $HEAT_USER_PWD heat_domain_admin
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
openstack role create heat_stack_owner
openstack role create heat_stack_user


#sleep 2
openstack project create --domain default  --description "Manager Tenant" manager
openstack user create --domain default --password $MANAGER_USER_PWD manager 
openstack role create manager
openstack role add --project manager --user manager  manager 
