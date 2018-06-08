#!/bin/bash

source ./master.conf

MASTER_NAME=`echo $HOSTNAME | grep 201`

#-------------Config glance service ---------------------------

test -f /etc/cinder/cinder.conf_bak || cp -a /etc/cinder/cinder.conf /etc/cinder/cinder.conf_bak
test -f /etc/glance/glance-registry.conf_bak || cp -a /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf_bak

sed -i '/^#/d' /etc/cinder/cinder.conf
sed -i '/^$/d' /etc/cinder/cinder.conf

openstack-config --set /etc/cinder/cinder.conf DEFAULT debug False
openstack-config --set /etc/cinder/cinder.conf DEFAULT log_dir /var/log/cinder
# rabbitmq
openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_ha_queues True

openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password $CINDER_USER_PWD
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000/v3
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url  http://$VIP_NAME:35357/v3

openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip $MASTER_IP
openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen $HOSTNAME
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT rados_connect_timeout -1
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_version 2
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_host $VIP_NAME
openstack-config --set /etc/cinder/cinder.conf DEFAULT volume_clear none
openstack-config --set /etc/cinder/cinder.conf DEFAULT image_conversion_dir /letv/openstack/cinder
openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_workers $(grep -c ^processor /proc/cpuinfo)
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends rbd-1
openstack-config --set /etc/cinder/cinder.conf DEFAULT scheduler_driver cinder.scheduler.filter_scheduler.FilterScheduler
openstack-config --set /etc/cinder/cinder.conf DEFAULT default_volume_type rbd-1

openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://$VIP_NAME:9292

openstack-config --set /etc/cinder/cinder.conf rbd-1 volume_driver cinder.volume.drivers.rbd.RBDDriver
openstack-config --set /etc/cinder/cinder.conf rbd-1 rbd_pool $VOLUMES_POOL
openstack-config --set /etc/cinder/cinder.conf rbd-1 rbd_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/cinder/cinder.conf rbd-1 rbd_flatten_volume_from_snapshot true
openstack-config --set /etc/cinder/cinder.conf rbd-1 rbd_max_clone_depth 1
openstack-config --set /etc/cinder/cinder.conf rbd-1 rbd_store_chunk_size 4
openstack-config --set /etc/cinder/cinder.conf rbd-1 rbd_user cinder
openstack-config --set /etc/cinder/cinder.conf rbd-1 rbd_secret_uuid $RBD_UUID
openstack-config --set /etc/cinder/cinder.conf rbd-1 rbd_user cinder
openstack-config --set /etc/cinder/cinder.conf rbd-1 volume_backend_name rbd-1

# database
openstack-config --set /etc/cinder/cinder.conf database connection  mysql://$CINDER_DB_USER:$CINDER_DB_PWD@mysqlserver:$CINDER_DB_PORT/$CINDER_DB_NAME
openstack-config --set /etc/cinder/cinder.conf database max_pool_size 100
openstack-config --set /etc/cinder/cinder.conf database max_overflow 200


if [ -n "$MASTER_NAME" ]; then
mkdir -p $CINDER_DIR
cp -av /var/lib/cinder $CINDER_DIR/
chown -R cinder:cinder $CINDER_DIR/cinder
fi

touch /var/log/cinder/api.log
touch /var/log/cinder/scheduler.log
touch /var/log/cinder/volume.log
touch /var/log/cinder/cinder-manage.log
chown -R cinder:cinder /var/log/cinder

if [ -n "$MASTER_NAME" ]; then
su -s /bin/sh -c "cinder-manage db sync" cinder
sleep 1
fi

systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl restart openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl enable openstack-cinder-volume.service target.service
systemctl restart openstack-cinder-volume.service target.service

cinder type-create rbd-1
cinder type-list
cinder type-key rbd-1 set volume_backend_name=rbd-1
cinder extra-specs-list
systemctl restart openstack-cinder-volume.service 
