#!/bin/bash

source ./master.conf
#VIP_NAME="m-231-200-pro01-nyc.ny-us.vps.letv.cn"

#keystone:
keystone tenant-create --name=$ADMIN_TENANT --description='Admin Tenant'
keystone tenant-create --name=service --description='Service Tenant'
sleep 1
keystone user-create --name=$ADMIN_USER --pass='LeTV!@#%*!#$&A' --email=keystone@chensh.net
keystone role-create --name=admin
keystone role-create --name=Member
keystone user-role-add --user=$ADMIN_USER --tenant=$ADMIN_TENANT --role=admin
keystone service-create --name=keystone --type=identity --description="Keystone Identity Service"
sleep 1
KEYSTONE_SERVICE=$(keystone service-list | awk '/keystone/ {print $2}')
keystone endpoint-create --service-id=$KEYSTONE_SERVICE --publicurl=http://$VIP_NAME:5000/v2.0 --internalurl=http://$VIP_NAME:5000/v2.0 --adminurl=http://$VIP_NAME:35357/v2.0

#glance:
keystone user-create --name=glance --pass=$GLANCE_USER_PWD --email=glance@chensh.net
keystone user-role-add --user=glance --tenant=service --role=admin
keystone service-create --name=glance --type=image --description="Glance Image Service"
sleep 1
GLANCE_SERVICE=$(keystone service-list | awk '/glance/ {print $2}')
keystone endpoint-create --service-id=$GLANCE_SERVICE --publicurl=http://$VIP_NAME:9292 --internalurl=http://$VIP_NAME:9292 --adminurl=http://$VIP_NAME:9292

#nova:
keystone user-create --name=nova --pass=$NOVA_USER_PWD --email=nova@chensh.net
keystone user-role-add --user=nova --tenant=service --role=admin
keystone service-create --name=nova --type=compute --description="Nova Compute Service"
sleep 1
NOVA_SERVICE=$(keystone service-list | awk '/nova/ {print $2}')
sleep 1
keystone endpoint-create --service-id=$NOVA_SERVICE --publicurl=http://$VIP_NAME:8774/v2/%\(tenant_id\)s --internalurl=http://$VIP_NAME:8774/v2/%\(tenant_id\)s --adminurl=http://$VIP_NAME:8774/v2/%\(tenant_id\)s

#neutron:
keystone user-create --name=neutron --pass=$NEUTRON_USER_PWD --email=neutron@chensh.net
keystone user-role-add --user=neutron --tenant=service --role=admin
keystone service-create --name=neutron --type=network --description="Neutron Network Service"
sleep 1
NEUTRON_SERVICE=$(keystone service-list | awk '/neutron/ {print $2}')
sleep 1
keystone endpoint-create --service-id=$NEUTRON_SERVICE --publicurl=http://$VIP_NAME:9696/ --internalurl=http://$VIP_NAME:9696/ --adminurl=http://$VIP_NAME:9696/

#cinder:
#keystone user-create --name=cinder --pass=$CINDER_USER_PWD --email=neutron@chensh.net
#keystone user-role-add --user=cinder --tenant=service --role=admin
#keystone service-create --name=cinder --type=volume --description="Cinder Volume Service"
#sleep 1
#CINDER_SERVICE=$(keystone service-list | awk '/cinder/ {print $2}')
#sleep 1
#keystone endpoint-create --service-id=$CINDER_SERVICE --publicurl=http://$VIP_NAME:8776/v1/%\(tenant_id\)s --internalurl=http://$VIP_NAME:8776/v1/%\(tenant_id\)s --adminurl=http://$VIP_NAME:8776/v1/%\(tenant_id\)s

sleep 2
keystone tenant-create --name=manager --description='Manager Tenant'
keystone user-create --name=manager --pass='yunweigl123!A' --email=manager@chensh.net
keystone role-create --name=manager
keystone user-role-add --user=manager --tenant=manager --role=manager
keystone user-role-add --user=nova --tenant=service --role=manager
