source ./master.conf 
#mysql -h $DB_SERVER -P $KEYSTONE_DB_PORT -u$KEYSTONE_DB_USER -p$KEYSTONE_DB_PWD -e "drop database keystone;create database keystone;"
#mysql -h $DB_SERVER -P $GLANCE_DB_PORT -u$GLANCE_DB_USER -p$GLANCE_DB_PWD -e "drop database glance;create database glance;"
mysql -h $DB_SERVER -P $NOVA_DB_PORT -u$NOVA_DB_USER -p$NOVA_DB_PWD -e "drop database nova;create database nova;"
mysql -h $DB_SERVER -P $NOVAAPI_DB_PORT -u$NOVAAPI_DB_USER -p$NOVAAPI_DB_PWD -e "drop database novaapi;create database novaapi;"
#mysql -h $DB_SERVER -P $NEUTRON_DB_PORT -u$NEUTRON_DB_USER -p$NEUTRON_DB_PWD -e "drop database neutron;create database neutron;"
#mysql -h $DB_SERVER -P $CINDER_DB_PORT -u$CINDER_DB_USER -p$CINDER_DB_PWD -e "drop database cinder;create database cinder;"
#mysql -h mysqlserver -P 3881 -uneutron -p95bd68d7e2 -e 'drop database neutron;create database neutron;'
