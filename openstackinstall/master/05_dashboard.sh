#!/bin/bash
# YUM rpm

source ./master.conf

rpm -ivh $OPENSTACK_REPO

# yum -y install openstack-dashboard python-django-horizon

sleep 1

cp -a /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings_bak 

sed -i '/DEBUG/ s/False/True/' /etc/openstack-dashboard/local_settings

sed -i "/ALLOWED_HOSTS/ s/]/, '*']/" /etc/openstack-dashboard/local_settings

sed -i "/OPENSTACK_HOST/ s/127.0.0.1/$VIP/" /etc/openstack-dashboard/local_settings

sed -i '/^SECRET_KEY/ s/^/# /' /etc/openstack-dashboard/local_settings

sed -i '108,112s/^/#/' /etc/openstack-dashboard/local_settings

cat > /tmp/dashboard_temp << EOF
SECRET_KEY = 'y3kT2DLiL1/n7cH/NbmfxA='
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

CACHES = {
    'default': {
        'BACKEND' : 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION' : ["$MASTER_A:11211","$MASTER_B:11211"],
    },
}
EOF

sed -i '/^# SECRET_KEY/r /tmp/dashboard_temp' /etc/openstack-dashboard/local_settings

rm -rf /tmp/dashboard_temp

cp -a /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_bak

sed -i "/^Listen 80/d" /etc/httpd/conf/httpd.conf
sed -i "/^#Listen/ a\Listen $MASTER_IP:$HTTP_PORT" /etc/httpd/conf/httpd.conf
sed -i "/^#ServerName/ a\ServerName $MASTER_IP:$HTTP_PORT" /etc/httpd/conf/httpd.conf

chkconfig httpd on
service httpd restart

chkconfig memcached on
service memcached restart

netstat -antp | grep :$HTTP_PORT

