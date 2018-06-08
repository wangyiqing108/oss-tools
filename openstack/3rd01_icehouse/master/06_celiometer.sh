#!/bin/bash
set -x
source ./master.conf

MASTER_NAME=`echo $HOSTNAME | grep 201`


#-------------Config glance service ---------------------------

test -f /etc/ceilometer/ceilometer.conf_bak || cp -a /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf_bak
test -f /etc/ceilometer/pipeline.yaml_bak || cp -a /etc/ceilometer/pipeline.yaml /etc/ceilometer/pipeline.yaml_bak
test -f /etc/ceilometer/event_definitions.yaml_bak || cp -a /etc/ceilometer/event_definitions.yaml  /etc/ceilometer/event_definitions.yaml_bak

sed -i '/^#/d' /etc/ceilometer/ceilometer.conf
sed -i '/^$/d' /etc/ceilometer/ceilometer.conf




# rabbit
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_ha_queues True

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT debug False
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone

openstack-config --set /etc/ceilometer/ceilometer.conf api host $HOSTNAME
openstack-config --set /etc/ceilometer/ceilometer.conf api port 8777

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT meter_dispatchers database
openstack-config --set /etc/ceilometer/ceilometer.conf dispatcher_openfalcon target http://$MASTER_NAME_A:1988/v1/push

openstack-config --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:$CEILOMETER_DBPASS@mongoserver:27018/ceilometer?replicaSet=ceilometer

openstack-config --set /etc/ceilometer/ceilometer.conf event drop_unmatched_notifications true
openstack-config --set /etc/ceilometer/ceilometer.conf notification store_events true
openstack-config --set /etc/ceilometer/ceilometer.conf publisher shrink_metadata true
openstack-config --set /etc/ceilometer/ceilometer.conf database metering_time_to_live 2592000
openstack-config --set /etc/ceilometer/ceilometer.conf database event_time_to_live 2592000

# keystone_authtoken
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_type password
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_name service
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken username ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken password $CEILOMETER_USER_PWD
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000/v3
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_url  http://$VIP_NAME:35357/v3

# service_credentials
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_type  password
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_url http://$VIP_NAME:5000/v3
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials user_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_name service
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials username ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials password $CEILOMETER_USER_PWD
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials interface internalURL
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials region_name RegionOne

sed -i '/meter_dispatchers = openfalcon/d' /etc/ceilometer/ceilometer.conf
sed -i "5a meter_dispatchers = openfalcon" /etc/ceilometer/ceilometer.conf

if [ -n "$MASTER_NAME" ]; then
mkdir -p $CEILOMETER_DIR
cp -av /var/lib/ceilometer $CEILOMETER_DIR/
chown -R ceilometer:ceilometer $CEILOMETER_DIR/ceilometer

fi

sed -i "s/notifier:\/\//udp:\/\/${CEILOMETER_UDP_SERVER}:4952/g" /etc/ceilometer/pipeline.yaml
sed -i "s/interval: 600/interval: 60/g" /etc/ceilometer/pipeline.yaml
touch /var/log/ceilometer/agent-notification.log
touch /var/log/ceilometer/alarm-evaluator.log
touch /var/log/ceilometer/central.log
touch /var/log/ceilometer/alarm-notifier.log
touch /var/log/ceilometer/api.log
touch /var/log/ceilometer/collector.log
chown -R ceilometer:ceilometer /var/log/ceilometer

if [ -n "$MASTER_NAME" ]; then
ceilometer-dbsync 
sleep 1
fi

systemctl enable openstack-ceilometer-api.service \
  openstack-ceilometer-notification.service \
  openstack-ceilometer-collector.service
systemctl restart openstack-ceilometer-api.service \
  openstack-ceilometer-notification.service \
  openstack-ceilometer-collector.service


openstack-config --set /etc/glance/glance-api.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_ha_queues True
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_notifications driver messagingv2
openstack-config --set /etc/glance/glance-registry.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_ha_queues True
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_notifications driver messagingv2
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_notifications driver messagingv2
systemctl restart openstack-glance-api.service openstack-glance-registry.service
systemctl restart openstack-cinder-api.service openstack-cinder-scheduler.service openstack-cinder-volume.service
