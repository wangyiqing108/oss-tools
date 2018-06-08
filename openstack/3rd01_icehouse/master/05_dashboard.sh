#!/bin/bash
# YUM rpm

source ./master.conf

sleep 1

cp -a /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings_bak 

sed -i '/DEBUG/ s/False/True/' /etc/openstack-dashboard/local_settings

sed -i "/ALLOWED_HOSTS/ s/]/, '*']/" /etc/openstack-dashboard/local_settings

sed -i "/OPENSTACK_HOST/ s/127.0.0.1/$VIP/" /etc/openstack-dashboard/local_settings
sed -i "s/_member_/user/g" /etc/openstack-dashboard/local_settings
sed -i '135,139s/^/#/' /etc/openstack-dashboard/local_settings

cat > /tmp/dashboard_temp << EOF
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

CACHES = {
    'default': {
        'BACKEND' : 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION' : ["$MASTER_A:11211","$MASTER_B:11211"],
    },
}

OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}

EOF

sed -i '/^# SECRET_KEY/r /tmp/dashboard_temp' /etc/openstack-dashboard/local_settings
sed -i 's/5000\/v2.0/5000\/v3/g' /etc/openstack-dashboard/local_settings
sed -i "s/#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN/g" /etc/openstack-dashboard/local_settings
#sed -i 's/#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g' /etc/openstack-dashboard/local_settings
rm -rf /tmp/dashboard_temp

cp -a /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_bak

sed -i "/^Listen 80/d" /etc/httpd/conf/httpd.conf
sed -i "/^#Listen/ a\Listen $MASTER_IP:$HTTP_PORT" /etc/httpd/conf/httpd.conf
sed -i "/^#ServerName/ a\ServerName $MASTER_IP:$HTTP_PORT" /etc/httpd/conf/httpd.conf

systemctl enable httpd.service memcached.service
systemctl restart httpd.service memcached.service

netstat -antp | grep :$HTTP_PORT

