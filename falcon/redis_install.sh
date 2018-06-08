#!bin/sh

#env
LOCALIP=`ifconfig |grep inet |grep -v '127.0' |awk '{print $2}'`

#redis
yum install -y redis

sed -i "s/^port 6379/port 6378/g" /etc/redis.conf 
sed -i "s/^bind 127.0.0.1/bind $LOCALIP 127.0.0.1/" /etc/redis.conf

systemctl enable redis
systemctl restart redis
systemctl status redis

netstat -anp |grep 6378
