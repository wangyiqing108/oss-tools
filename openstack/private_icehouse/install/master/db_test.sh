#!/bin/bash

source ./master.conf

echo "1.Keystone DB connect test ------->"
mysql -h $DB_SERVER -P $KEYSTONE_DB_PORT -u$KEYSTONE_DB_USER -p$KEYSTONE_DB_PWD -e "show databases;"

echo "2.Glance DB connect test --------->"
mysql -h $DB_SERVER -P $GLANCE_DB_PORT -u$GLANCE_DB_USER -p$GLANCE_DB_PWD -e "show databases;"

echo "3.Nova DB connect test ----------->"
mysql -h $DB_SERVER -P $NOVA_DB_PORT -u$NOVA_DB_USER -p$NOVA_DB_PWD -e "show databases;"

echo "4.Neutron DB connect test -------->"
mysql -h $DB_SERVER -P $NEUTRON_DB_PORT -u$NEUTRON_DB_USER -p$NEUTRON_DB_PWD -e "show databases;"

