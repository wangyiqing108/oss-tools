#!/bin/bash
# file
source ./master.conf

sed -i "7s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config > /dev/null
sed -i "2s/install/#install/" /etc/modprobe.d/nf_conntrack.conf > /dev/null


#-------------Config keystone service -------------------------

test -f /etc/keystone/keystone.conf_bak || cp -a /etc/keystone/keystone.conf /etc/keystone/keystone.conf_bak

sed -i '/^#/d' /etc/keystone/keystone.conf
sed -i '/^$/d' /etc/keystone/keystone.conf

#-------------Config qpidd service ---------------------------

#sed -i "38s/auth=yes/auth=no/" /etc/qpidd.conf
#service qpidd start
#chkconfig qpidd on

#-------------Config keystone service -------------------------

openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $TOKEN
openstack-config --set /etc/keystone/keystone.conf DEFAULT bind_host $HOSTNAME

# rabbitmq
openstack-config --set /etc/keystone/keystone.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_hosts "$RABBIT_NAME_A:5672, $RABBIT_NAME_B:5672"
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_ha_queues True

openstack-config --set /etc/keystone/keystone.conf catalog driver sql
openstack-config --set /etc/keystone/keystone.conf token expiration 86400
openstack-config --set /etc/keystone/keystone.conf revoke driver sql
openstack-config --set /etc/keystone/keystone.conf assignment driver sql
openstack-config --set /etc/keystone/keystone.conf token provider fernet

# database
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://$KEYSTONE_DB_USER:$KEYSTONE_DB_PWD@mysqlserver:$KEYSTONE_DB_PORT/$KEYSTONE_DB_NAME
openstack-config --set /etc/keystone/keystone.conf database max_pool_size 100
openstack-config --set /etc/keystone/keystone.conf database max_overflow 200

MASTER_NAME=`echo $HOSTNAME | grep 201`

if [ -n "$MASTER_NAME" ]; then
    keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
fi

sleep 2

touch /var/log/keystone/keystone.log
chown -R keystone:keystone /etc/keystone/* /var/log/keystone/keystone.log

sed -i "/OS_/d" ~/.bash_profile
sed -i "11a export OS_PROJECT_DOMAIN_NAME=default" ~/.bash_profile
sed -i "11a export OS_USER_DOMAIN_NAME=default" ~/.bash_profile
sed -i "11a export OS_PROJECT_NAME=admin" ~/.bash_profile
sed -i "11a export OS_USERNAME=$ADMIN_USER" ~/.bash_profile
sed -i "11a export OS_PASSWORD=\'$ADMIN_PWD\'" ~/.bash_profile
sed -i "11a export OS_AUTH_URL=http://$VIP_NAME:35357/v3" ~/.bash_profile
sed -i "11a export OS_URL=http://$VIP_NAME:35357/v3" ~/.bash_profile
sed -i "11a export OS_TOKEN=$TOKEN" ~/.bash_profile
sed -i "11a export OS_IDENTITY_API_VERSION=3" ~/.bash_profile
sed -i "11a export OS_IMAGE_API_VERSION=2" ~/.bash_profile

source ~/.bash_profile


if [ -n "$MASTER_NAME" ]; then
echo "---------------------------------------------"
echo "Please execute follow command:"
echo 'su -s /bin/sh -c "keystone-manage db_sync" keystone'
echo "scp -r /etc/keystone/fernet-keys root@$MASTER_NAME_B:/etc/keystone/"
echo "scp -r /etc/keystone/fernet-keys root@$MASTER_NAME_C:/etc/keystone/"
echo "scp -r /etc/keystone/fernet-keys root@$MASTER_NAME_D:/etc/keystone/"
echo "source ~/.bash_profile"
echo "service openstack-keystone start"
echo "---------------------------------------------"

fi


systemctl stop openstack-keystone.service
systemctl disable openstack-keystone.service

systemctl enable memcached.service
systemctl start memcached.service

