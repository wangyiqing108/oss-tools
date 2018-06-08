#!/bin/sh

if ! which mysql ;then
    yum install -y mysql
fi     

mysql -h mysqlserver -u graph -P 4407 -p6Sfsf3rgw2 <graph-db-schema.sql
echo "********* graph *********"
echo 'show tables;' |mysql -h mysqlserver -u graph -P 4407 -p6Sfsf3rgw2 -D graph

mysql -h mysqlserver -u dashboard -P 4407 -p6Sfsf3rgw2 <dashboard-db-schema.sql
echo "********* dashboard *********"
echo 'show tables;' |mysql -h mysqlserver -u dashboard -P 4407 -p6Sfsf3rgw2 -D dashboard

mysql -h mysqlserver -u falcon_links -P 4407 -p6Sfsf3rgw2 <links-db-schema.sql 
echo "********* falcon_links *********"
echo 'show tables;' |mysql -h mysqlserver -u falcon_links -P 4407 -p6Sfsf3rgw2 -D falcon_links

mysql -h mysqlserver -u falcon_portal -P 4407 -p6Sfsf3rgw2 <portal-db-schema.sql 
echo "********* falcon_portal *********"
echo 'show tables;' |mysql -h mysqlserver -u falcon_portal -P 4407 -p6Sfsf3rgw2 -D falcon_portal

mysql -h mysqlserver -u uic -P 4407 -p6Sfsf3rgw2 <uic-db-schema.sql
echo "********* uic *********"
echo 'show tables;' |mysql -h mysqlserver -u uic -P 4407 -p6Sfsf3rgw2 -D uic      
