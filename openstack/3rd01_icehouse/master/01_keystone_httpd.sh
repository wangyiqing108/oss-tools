#!/bin/bash

# file
source ./master.conf


if [ -d /etc/keystone/ssl ]
then
	chown -R keystone:keystone /etc/keystone/ssl
	chmod -R o-rwx /etc/keystone/ssl
fi
restorecon /var/www/cgi-bin
#
usermod -a -G keystone apache


# config httpd
echo 'Listen 15001
Listen 45358

<VirtualHost *:15001>
    WSGIDaemonProcess keystone-public processes=12 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

<Directory /usr/bin>
    Require all granted
</Directory>

</VirtualHost>

<VirtualHost *:45358>
    WSGIDaemonProcess keystone-admin processes=12 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

<Directory /usr/bin>
    Require all granted
</Directory>

</VirtualHost>' > /etc/httpd/conf.d/wsgi-keystone.conf
service haproxy stop
sed -i "/^Listen 80/d" /etc/httpd/conf/httpd.conf

systemctl enable httpd.service
systemctl start httpd.service
systemctl restart httpd.service

# config Haproxy
sed -i 's/35357 check/45358 check/g' /etc/haproxy/haproxy.cfg
sed -i 's/5000 check/15001 check/g' /etc/haproxy/haproxy.cfg
service haproxy restart

cat /etc/keystone/keystone-paste.ini > /usr/share/keystone/keystone-dist-paste.ini
systemctl restart httpd 

sed -i 's/^export OS_TOKEN/#export OS_TOKEN/g' /root/.bash_profile 
source /root/.bash_profile
