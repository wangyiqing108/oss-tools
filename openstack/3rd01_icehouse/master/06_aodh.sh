#!/bin/bash

source ./master.conf

MASTER_NAME=`echo $HOSTNAME | grep 201`


#-------------Config glance service ---------------------------

test -f /etc/aodh/aodh.conf_bak || cp -a /etc/aodh/aodh.conf /etc/aodh/aodh.conf_bak

sed -i '/^#/d' /etc/aodh/aodh.conf
sed -i '/^$/d' /etc/aodh/aodh.conf

# rabbit
openstack-config --set /etc/aodh/aodh.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_ha_queues True

openstack-config --set /etc/aodh/aodh.conf DEFAULT debug False
openstack-config --set /etc/aodh/aodh.conf DEFAULT auth_strategy keystone

openstack-config --set /etc/aodh/aodh.conf api host $HOSTNAME
openstack-config --set /etc/aodh/aodh.conf api port 8042

# keystone_authtoken
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_type password
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken project_name service
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken username aodh
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken password $AODH_USER_PWD
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000/v3
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_url  http://$VIP_NAME:35357/v3

# service_credentials
openstack-config --set /etc/aodh/aodh.conf service_credentials auth_type  password
openstack-config --set /etc/aodh/aodh.conf service_credentials auth_url http://$VIP_NAME:5000/v3
openstack-config --set /etc/aodh/aodh.conf service_credentials project_domain_name default
openstack-config --set /etc/aodh/aodh.conf service_credentials user_domain_name default
openstack-config --set /etc/aodh/aodh.conf service_credentials project_name service
openstack-config --set /etc/aodh/aodh.conf service_credentials username aodh
openstack-config --set /etc/aodh/aodh.conf service_credentials password $AODH_USER_PWD
openstack-config --set /etc/aodh/aodh.conf service_credentials interface internalURL
openstack-config --set /etc/aodh/aodh.conf service_credentials region_name RegionOne

# database
openstack-config --set /etc/aodh/aodh.conf database connection mysql+pymysql://$AODH_DB_USER:$AODH_DB_PWD@mysqlserver:$AODH_DB_PORT/$AODH_DB_NAME

if [ -n "$MASTER_NAME" ]; then
aodh-dbsync
sleep 1
fi

systemctl enable openstack-aodh-api.service \
  openstack-aodh-evaluator.service \
  openstack-aodh-notifier.service \
  openstack-aodh-listener.service
systemctl restart openstack-aodh-api.service \
  openstack-aodh-evaluator.service \
  openstack-aodh-notifier.service \
  openstack-aodh-listener.service


