#!/bin/bash

source ./master.conf

# yum rpm
rpm -ivh $OPENSTACK_REPO

# yum -y install openstack-cinder

MASTER_NAME=`echo $HOSTNAME | grep 201`


#-------------Config glance service ---------------------------

cp -a /etc/cinder/cinder.conf /etc/cinder/cinder.conf_bak
cp -a /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf_bak

sed -i '/^#/d' /etc/cinder/cinder.conf
sed -i '/^$/d' /etc/cinder/cinder.conf

openstack-config --set /etc/cinder/cinder.conf DEFAULT debug False
openstack-config --set /etc/cinder/cinder.conf DEFAULT verbose True
openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend cinder.openstack.common.rpc.impl_kombu
openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen $HOSTNAME
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT volume_driver cinder.volume.drivers.rbd.RBDDriver
openstack-config --set /etc/cinder/cinder.conf DEFAULT rbd_pool volumes
openstack-config --set /etc/cinder/cinder.conf DEFAULT rbd_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/cinder/cinder.conf DEFAULT rbd_flatten_volume_from_snapshot false
openstack-config --set /etc/cinder/cinder.conf DEFAULT rbd_max_clone_depth 5
openstack-config --set /etc/cinder/cinder.conf DEFAULT rbd_store_chunk_size 4
openstack-config --set /etc/cinder/cinder.conf DEFAULT rados_connect_timeout -1
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_version 2
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_host $VIP_NAME
openstack-config --set /etc/cinder/cinder.conf DEFAULT rbd_user cinder
openstack-config --set /etc/cinder/cinder.conf DEFAULT rbd_secret_uuid 457eb676-33da-42ec-9a8c-9293d545c337
openstack-config --set /etc/cinder/cinder.conf DEFAULT volume_clear none
openstack-config --set /etc/cinder/cinder.conf DEFAULT image_conversion_dir /letv/openstack/cinder
openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_hosts  "$MASTER_NAME_A:5672, $MASTER_NAME_B:5672"
openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_userid $RABBIT_USERID
openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_ha_queues True

openstack-config --set /etc/cinder/cinder.conf database connection  mysql://$CINDER_DB_USER:$CINDER_DB_PWD@mysqlserver:$CINDER_DB_PORT/$CINDER_DB_NAME

openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_host  $VIP_NAME
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_port  35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_protocol  http
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name  service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_user  cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_password  $CINDER_USER_PWD
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken identity_uri  http://$VIP_NAME:35357


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
cinder-manage db sync
sleep 1
fi

service openstack-cinder-api restart       
service openstack-cinder-backup restart    
service openstack-cinder-scheduler restart
service openstack-cinder-volume restart
chkconfig openstack-cinder-api on
chkconfig openstack-cinder-backup on
chkconfig openstack-cinder-scheduler on
chkconfig openstack-cinder-volume on


