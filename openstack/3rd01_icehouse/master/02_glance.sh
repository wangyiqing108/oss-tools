#!/bin/bash

source ./master.conf

MASTER_NAME=`echo $HOSTNAME | grep 201`


#-------------Config glance service ---------------------------

openstack-config --del  /etc/keystone/keystone.conf DEFAULT admin_token
systemctl restart httpd
sleep 1

test -f /etc/glance/glance-api.conf_bak || cp -a /etc/glance/glance-api.conf /etc/glance/glance-api.conf_bak
test -f /etc/glance/glance-registry.conf_bak || cp -a /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf_bak

sed -i '/^#/d' /etc/glance/glance-api.conf
sed -i '/^$/d' /etc/glance/glance-api.conf
sed -i '/^#/d' /etc/glance/glance-registry.conf
sed -i '/^$/d' /etc/glance/glance-registry.conf

openstack-config --set /etc/glance/glance-api.conf DEFAULT debug False
openstack-config --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
openstack-config --set /etc/glance/glance-api.conf DEFAULT image_cache_dir  $GLANCE_DIR/glance/image-cache
openstack-config --set /etc/glance/glance-api.conf DEFAULT log_dir /var/log/glance
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host  $HOSTNAME
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_port  9292
openstack-config --set /etc/glance/glance-api.conf DEFAULT registry_host  $HOSTNAME
openstack-config --set /etc/glance/glance-api.conf DEFAULT registry_port  9191
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host $HOSTNAME
openstack-config --set /etc/glance/glance-api.conf DEFAULT workers $(grep -c ^processor /proc/cpuinfo)

openstack-config --set /etc/glance/glance-api.conf glance_store stores rbd,file
openstack-config --set /etc/glance/glance-api.conf glance_store default_store  rbd
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_user glance
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_pool $IMAGES_POOL
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_chunk_size 8
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/glance/glance-api.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_ha_queues True

openstack-config --set /etc/glance/glance-api.conf database connection  mysql+pymysql://$GLANCE_DB_USER:$GLANCE_DB_PWD@mysqlserver:$GLANCE_DB_PORT/$GLANCE_DB_NAME
openstack-config --set /etc/glance/glance-api.conf database max_pool_size 50
openstack-config --set /etc/glance/glance-api.conf database max_overflow 100

openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken password $GLANCE_USER_PWD
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000/v3
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url  http://$VIP_NAME:35357/v3

openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor  keystone

#-----------------------------------------------------------------------------------------------------------------------------------------------------

openstack-config --set /etc/glance/glance-registry.conf DEFAULT bind_host  $HOSTNAME
openstack-config --set /etc/glance/glance-registry.conf DEFAULT bind_port  9191
openstack-config --set /etc/glance/glance-registry.conf database connection  mysql+pymysql://$GLANCE_DB_USER:$GLANCE_DB_PWD@mysqlserver:$GLANCE_DB_PORT/$GLANCE_DB_NAME

openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken password $GLANCE_USER_PWD
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000/v3
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url  http://$VIP_NAME:35357/v3

openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor  keystone

#-----------------------------------------------------------------------------------------------------------------------------------------------------

cp -a /usr/share/glance/glance-api-dist-paste.ini /etc/glance/glance-api-paste.ini
cp -a /usr/share/glance/glance-registry-dist-paste.ini /etc/glance/glance-registry-paste.ini

chown root:glance /etc/glance/glance-api-paste.ini
chown root:glance /etc/glance/glance-registry-paste.ini

if [ -n "$MASTER_NAME" ]; then
mkdir -p $GLANCE_DIR
cp -av /var/lib/glance $GLANCE_DIR/
chown -R glance:glance $GLANCE_DIR/glance
fi

touch /var/log/glance/api.log
touch /var/log/glance/registry.log
chown -R glance:glance /var/log/glance

if [ -n "$MASTER_NAME" ]; then
su -s /bin/sh -c "glance-manage db_sync" glance
sleep 1
fi

systemctl enable openstack-glance-api.service  
systemctl enable openstack-glance-registry.service
systemctl restart openstack-glance-api.service  
systemctl restart openstack-glance-registry.service
