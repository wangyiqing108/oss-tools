#!/bin/bash
set -x
source ./master.conf

echo "1.Keystone DB connect test ------->"
mysql -h $DB_SERVER -P $KEYSTONE_DB_PORT -u$KEYSTONE_DB_USER -p$KEYSTONE_DB_PWD -e "show databases;"

echo "2.GLANCE DB connect test --------->"
mysql -h $DB_SERVER -P $GLANCE_DB_PORT -u$GLANCE_DB_USER -p$GLANCE_DB_PWD -e "show databases;"

echo "3.Nova DB connect test ----------->"
mysql -h $DB_SERVER -P $NOVA_DB_PORT -u$NOVA_DB_USER -p$NOVA_DB_PWD -e "show databases;"

echo "3.Nova Api DB connect test ----------->"
mysql -h $DB_SERVER -P $NOVAAPI_DB_PORT -u$NOVAAPI_DB_USER -p$NOVAAPI_DB_PWD -e "show databases;"

echo "4.Neutron DB connect test -------->"
mysql -h $DB_SERVER -P $NEUTRON_DB_PORT -u$NEUTRON_DB_USER -p$NEUTRON_DB_PWD -e "show databases;"

echo "5.Cinder DB connect test -------->"
mysql -h $DB_SERVER -P $CINDER_DB_PORT -u$CINDER_DB_USER -p$CINDER_DB_PWD -e "show databases;"

echo "6.Adoh DB connect test -------->"
mysql -h $DB_SERVER -P $AODH_DB_PORT -u$AODH_DB_USER -p$AODH_DB_PWD -e "show databases;"
