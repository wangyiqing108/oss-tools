#!/bin/bash
# yum -y install openstack-dashboard python-django-horizon

source ./master.conf

# yum rpm
#rpm -ivh $OPENSTACK_REP

# yum install openstack-heat-api openstack-heat-engine openstack-heat-api-cfn python-heatclient

MASTER_NAME=`echo $HOSTNAME | grep 90`
MASTER_IP=`more /etc/hosts | grep $HOSTNAME | awk '{print $1}'`

echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"

#-------------Config heat service -----------------------------

chown -R heat:heat /var/log/heat

cp -a /etc/heat/heat.conf /etc/heat/heat.conf_bak

sed -i '/^#/d' /etc/heat/heat.conf
sed -i '/^$/d' /etc/heat/heat.conf


# logging
openstack-config --set /etc/heat/heat.conf DEFAULT debug False
openstack-config --set /etc/heat/heat.conf DEFAULT verbose True
openstack-config --set /etc/heat/heat.conf DEFAULT default_log_levels amqplib=WARN,sqlalchemy=WARN,boto=WARN,suds=INFO,qpid.messaging=INFO,iso8601.iso8601=INFO

# rabbit
openstack-config --set /etc/heat/heat.conf DEFAULT rpc_backend heat.openstack.common.rpc.impl_kombu
openstack-config --set /etc/heat/heat.conf DEFAULT rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/heat/heat.conf DEFAULT rabbit_userid $RABBIT_USERID
openstack-config --set /etc/heat/heat.conf DEFAULT rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/heat/heat.conf DEFAULT rabbit_ha_queues True

# database
openstack-config --set /etc/heat/heat.conf database connection mysql://$HEAT_DB_USER:$HEAT_DB_PWD@mysqlserver:$HEAT_DB_PORT/$HEAT_DB_NAME

# keystone_authtoken
openstack-config --set /etc/heat/heat.conf keystone_authtoken auth_host $VIP_NAME
openstack-config --set /etc/heat/heat.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/heat/heat.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/heat/heat.conf keystone_authtoken admin_user heat
openstack-config --set /etc/heat/heat.conf keystone_authtoken admin_tenant_name service
openstack-config --set /etc/heat/heat.conf keystone_authtoken admin_password $HEAT_USER_PWD
openstack-config --set /etc/heat/heat.conf keystone_authtoken auth_host  $VIP_NAME
openstack-config --set /etc/heat/heat.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000/v2.0
openstack-config --set /etc/heat/heat.conf keystone_authtoken identity_uri  http://$VIP_NAME:5000
openstack-config --set /etc/heat/heat.conf ec2authtoken auth_uri http://$VIP_NAME:5000/v2.0
openstack-config --set /etc/heat/heat.conf ec2authtoken keystone_ec2_uri http://$VIP_NAME:5000/v2.0/ec2tokens

openstack-config --set /etc/heat/heat.conf  DEFAULT heat_metadata_server_url http://$VIP:8000
openstack-config --set /etc/heat/heat.conf  DEFAULT heat_waitcondition_server_url http://$VIP:8000/v1/waitcondition

openstack-config --set /etc/heat/heat.conf heat_api bind_host $HOSTNAME
openstack-config --set /etc/heat/heat.conf heat_api bind_port 8004
openstack-config --set /etc/heat/heat.conf heat_api_cfn bind_host $HOSTNAME
openstack-config --set /etc/heat/heat.conf heat_api_cfn bind_port 8000
openstack-config --set /etc/heat/heat.conf heat_api_cloudwatch bind_host $HOSTNAME
openstack-config --set /etc/heat/heat.conf heat_api_cloudwatch bind_port 8003

#-------------Config service -----------------------------
#-------------Add heat user ssh -----------------------------------
usermod -d /var/lib/heat -s /bin/bash heat


if [ -n "$MASTER_NAME" ]; then
heat-manage db_sync
fi
sleep 5
service openstack-heat-api restart
service openstack-heat-api-cfn restart
service openstack-heat-engine restart
chkconfig openstack-heat-api on
chkconfig openstack-heat-api-cfn on
chkconfig openstack-heat-engine on
