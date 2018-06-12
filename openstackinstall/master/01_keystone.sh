#!/bin/bash

# file
source ./master.conf

# yum rpm
#rpm -ivh $OPENSTACK_REPO

#yum -y install rabbitmq-server mysql memcached
#yum -y install openstack-utils openstack-keystone python-keystoneclient


sed -i "7s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config > /dev/null

sed -i "2s/install/#install/" /etc/modprobe.d/nf_conntrack.conf > /dev/null

service iptables stop > /dev/null
service ip6tables stop > /dev/null

chkconfig  iptables off 
chkconfig  ip6tables off

echo "-------------------Config grub.conf---------------------------"

sed -i "11s/timeout=5/timeout=0/" /boot/grub/grub.conf 

echo "**********************************************************"
echo "                3.LeTV Cloud Node Config                  "
echo "**********************************************************"

#-------------Config keystone service -------------------------

cp -a /etc/keystone/keystone.conf /etc/keystone/keystone.conf_bak

sed -i '/^#/d' /etc/keystone/keystone.conf
sed -i '/^$/d' /etc/keystone/keystone.conf

#-------------Config qpidd service ---------------------------

#sed -i "38s/auth=yes/auth=no/" /etc/qpidd.conf

#service qpidd start

#chkconfig qpidd on

#-------------Config keystone service -------------------------

openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $TOKEN
openstack-config --set /etc/keystone/keystone.conf DEFAULT bind_host $HOSTNAME

openstack-config --set /etc/keystone/keystone.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/keystone/keystone.conf DEFAULT rabbit_hosts "$MASTER_NAME_A:5672, $MASTER_NAME_B:5672"
openstack-config --set /etc/keystone/keystone.conf DEFAULT rabbit_userid $RABBIT_USERID
openstack-config --set /etc/keystone/keystone.conf DEFAULT rabbit_password $RABBIT_PASSWD
openstack-config --set /etc/keystone/keystone.conf DEFAULT rabbit_ha_queues True

openstack-config --set /etc/keystone/keystone.conf database connection mysql://$KEYSTONE_DB_USER:$KEYSTONE_DB_PWD@mysqlserver:$KEYSTONE_DB_PORT/$KEYSTONE_DB_NAME

MASTER_NAME=`echo $HOSTNAME | grep 201`

if [ -n "$MASTER_NAME" ]; then
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
fi

sleep 2

touch /var/log/keystone/keystone.log
chown -R keystone:keystone /etc/keystone/* /var/log/keystone/keystone.log

sed -i "11a export SERVICE_TOKEN=$TOKEN" ~/.bash_profile
sed -i "11a export SERVICE_ENDPOINT=http://$VIP_NAME:35357/v2.0" ~/.bash_profile
sed -i "11a export OS_AUTH_URL=http://$VIP_NAME:5000/v2.0" ~/.bash_profile
sed -i "11a export OS_PASSWORD=\'$ADMIN_PWD\'" ~/.bash_profile
sed -i "11a export OS_TENANT_NAME=$ADMIN_TENANT" ~/.bash_profile
sed -i "11a export OS_USERNAME=$ADMIN_USER" ~/.bash_profile

source ~/.bash_profile


if [ -n "$MASTER_NAME" ]; then
echo "---------------------------------------------"
echo "Please execute follow command:"
echo "keystone-manage db_sync"
echo "scp -r /etc/keystone/ssl root@$MASTER_NAME_B:/etc/keystone/"
echo "source ~/.bash_profile"
echo "service openstack-keystone start"
echo "---------------------------------------------"

fi

chkconfig openstack-keystone on

