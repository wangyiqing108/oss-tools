#!/bin/bash

source ./master.conf

# yum rpm
rpm -ivh $OPENSTACK_REPO

# yum -y install openstack-glance

MASTER_NAME=`echo $HOSTNAME | grep 201`

#if [ -n "$MASTER_NAME" ]; then

#-------------Create glance user -------------------------------

#keystone user-create --name=glance --pass=$GLANCE_USER_PWD --email=glance@chensh.net

#keystone user-role-add --user=glance --tenant=service --role=admin

#keystone service-create --name=glance --type=image --description="Glance Image Service"
#sleep 1
#-------------Define Services and API Endpoints ---------------
#glance

#glance_service=$(keystone service-list | awk '/glance/ {print $2}')
#keystone endpoint-create --service-id=$glance_service --publicurl=http://$VIP_NAME:9292 --internalurl=http://$VIP_NAME:9292 --adminurl=http://$VIP_NAME:9292
#sleep 1

#fi

#-------------Config glance service ---------------------------

cp -a /etc/glance/glance-api.conf /etc/glance/glance-api.conf_bak
cp -a /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf_bak

sed -i '/^#/d' /etc/glance/glance-api.conf
sed -i '/^$/d' /etc/glance/glance-api.conf
sed -i '/^#/d' /etc/glance/glance-registry.conf
sed -i '/^$/d' /etc/glance/glance-registry.conf

openstack-config --set /etc/glance/glance-api.conf DEFAULT debug False
openstack-config --set /etc/glance/glance-api.conf DEFAULT verbose True
openstack-config --set /etc/glance/glance-api.conf DEFAULT default_store  file
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host  $HOSTNAME
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_port  9292
openstack-config --set /etc/glance/glance-api.conf DEFAULT registry_host  $HOSTNAME
openstack-config --set /etc/glance/glance-api.conf DEFAULT registry_port  9191
openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_hosts  "$MASTER_NAME_A:5672, $MASTER_NAME_B:5672"
openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_userid $RABBIT_USERID
openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_ha_queues True

openstack-config --set /etc/glance/glance-api.conf DEFAULT filesystem_store_datadir  $GLANCE_DIR/glance/images
openstack-config --set /etc/glance/glance-api.conf DEFAULT scrubber_datadir  $GLANCE_DIR/glance/scrubber
openstack-config --set /etc/glance/glance-api.conf DEFAULT image_cache_dir  $GLANCE_DIR/glance/image-cache
openstack-config --set /etc/glance/glance-api.conf DEFAULT rpc_backend  rabbit
openstack-config --set /etc/glance/glance-api.conf DEFAULT known_stores  glance.store.filesystem.Store

openstack-config --set /etc/glance/glance-api.conf database connection  mysql://$GLANCE_DB_USER:$GLANCE_DB_PWD@mysqlserver:$GLANCE_DB_PORT/$GLANCE_DB_NAME

openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_host  $VIP_NAME
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_port  35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_protocol  http
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name  service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_user  glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_password  $GLANCE_USER_PWD
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken identity_uri  http://$VIP_NAME:35357

openstack-config --set /etc/glance/glance-api.conf paste_deploy config_file  /etc/glance/glance-api-paste.ini
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor  keystone

#-----------------------------------------------------------------------------------------------------------------------------------------------------

openstack-config --set /etc/glance/glance-registry.conf DEFAULT bind_host  $HOSTNAME
openstack-config --set /etc/glance/glance-registry.conf DEFAULT bind_port  9191
openstack-config --set /etc/glance/glance-registry.conf database connection  mysql://$GLANCE_DB_USER:$GLANCE_DB_PWD@mysqlserver:$GLANCE_DB_PORT/$GLANCE_DB_NAME
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_host  $VIP_NAME
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_port  35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_protocol  http
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name  service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_user  glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_password  $GLANCE_USER_PWD
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri  http://$VIP_NAME:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken identity_uri  http://$VIP_NAME:35357

openstack-config --set /etc/glance/glance-registry.conf paste_deploy config_file  /etc/glance/glance-registry-paste.ini
openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor  keystone

#-----------------------------------------------------------------------------------------------------------------------------------------------------

cp -a /usr/share/glance/glance-api-dist-paste.ini /etc/glance/glance-api-paste.ini
cp -a /usr/share/glance/glance-registry-dist-paste.ini /etc/glance/glance-registry-paste.ini

chown root:glance /etc/glance/glance-api-paste.ini
chown root:glance /etc/glance/glance-registry-paste.ini

cp -a /etc/glance/glance-api-paste.ini /etc/glance/glance-api-paste.ini_bak
sed -i '/^#/d' /etc/glance/glance-api-paste.ini
sed -i '/^$/d' /etc/glance/glance-api-paste.ini

openstack-config --set /etc/glance/glance-api-paste.ini filter:authtoken auth_host $VIP_NAME
openstack-config --set /etc/glance/glance-api-paste.ini filter:authtoken admin_tenant_name service
openstack-config --set /etc/glance/glance-api-paste.ini filter:authtoken admin_user glance
openstack-config --set /etc/glance/glance-api-paste.ini filter:authtoken admin_password $GLANCE_USER_PWD

cp -a /etc/glance/glance-registry-paste.ini /etc/glance/glance-registry-paste.ini_bak
sed -i '/^#/d' /etc/glance/glance-registry-paste.ini
sed -i '/^$/d' /etc/glance/glance-registry-paste.ini

openstack-config --set /etc/glance/glance-registry-paste.ini filter:authtoken auth_host $VIP_NAME
openstack-config --set /etc/glance/glance-registry-paste.ini filter:authtoken admin_tenant_name service
openstack-config --set /etc/glance/glance-registry-paste.ini filter:authtoken admin_user glance
openstack-config --set /etc/glance/glance-registry-paste.ini filter:authtoken admin_password $GLANCE_USER_PWD

if [ -n "$MASTER_NAME" ]; then
mkdir -p $GLANCE_DIR
cp -av /var/lib/glance $GLANCE_DIR/
chown -R glance:glance $GLANCE_DIR/glance
fi

touch /var/log/glance/api.log
touch /var/log/glance/registry.log
chown -R glance:glance /var/log/glance

if [ -n "$MASTER_NAME" ]; then
glance-manage db_sync
sleep 1
fi

service openstack-glance-api restart
service openstack-glance-registry restart
chkconfig openstack-glance-api on
chkconfig openstack-glance-registry on

#echo "glance-manage db_sync"

