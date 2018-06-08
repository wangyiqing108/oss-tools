#!/bin/bash

#env

INTERFACE=br0
ID=243


LOCALIP=`ifconfig |grep inet |grep -v '127.0' |awk '{print $2}'`
IPTHIRD=`ip -o -f inet add show |grep br0|head -1|awk '{print $4}'|awk -F '/' '{print $1}' |awk -F '.' '{print $3}'`

VIP=10.248.${IPTHIRD}.243
FALCON_A=10.248.${IPTHIRD}.224
FALCON_B=10.248.${IPTHIRD}.225
FALCON_A_NAME=falcon-${IPTHIRD}-224
FALCON_B_NAME=falcon-${IPTHIRD}-225

if [ ${LOCALIP} = ${FALCON_A} ] ;then
   KEEPALIVE=MASTER
else
   KEEPALIVE=BACKUP
fi

sed -i 's/^install nf_conntrack/#install nf_conntrack/g'  /etc/modprobe.d/nf_conntrack.conf 

sed -i "/net.ipv4.ip_forward/ s/0/1/" /etc/sysctl.conf

#echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
sed -i "s/net.ipv4.conf.default.rp_filter = 2/net.ipv4.conf.default.rp_filter = 0/" /etc/sysctl.conf > /dev/null
sed -i "s/net.ipv4.conf.all.rp_filter = 2/net.ipv4.conf.all.rp_filter = 0/" /etc/sysctl.conf > /dev/null

sysctl -p

yum -y install keepalived haproxy
test -f /etc/keepalived/keepalived.conf_bak || cp -av /etc/keepalived/keepalived.conf  /etc/keepalived/keepalived.conf_bak
test -f /etc/haproxy/haproxy.cfg_bak || cp -av /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg_bak


cat > /etc/keepalived/keepalived.conf << EOF
vrrp_script haproxy-check {
    script "killall -0 haproxy"
    interval 2
    weight 10
}
vrrp_instance openstack-vip {
    state $KEEPALIVE
    priority 102
    interface $INTERFACE
    virtual_router_id $ID
    advert_int 3
    virtual_ipaddress {
        $VIP
    }
    track_script {
        haproxy-check
    }
}

EOF

cat > /etc/haproxy/haproxy.cfg << EOF
global
    daemon
    stats socket  /var/lib/haproxy/stats


defaults
    maxconn 10000
    timeout connect 300s
    timeout client 300s
    timeout server 300s

frontend falcon-fe-vip
    bind $VIP:1234
    default_backend falcon-fe

frontend falcon-portal-vip
    bind $VIP:5050
    default_backend falcon-portal

frontend falcon-dashboard-vip
    bind $VIP:8081
    default_backend falcon-dashboard

frontend falcon-query-vip
    bind $VIP:9966
    default_backend falcon-query

frontend falcon-hbs-vip
    bind $VIP:6030
    default_backend falcon-hbs

frontend falcon-transfer-http-vip
    bind $VIP:6060
    default_backend falcon-transfer-http

frontend falcon-transfer-vip
    bind $VIP:8433
    default_backend falcon-transfer
    
frontend falcon-alarm-vip
    bind $VIP:6067
    default_backend falcon-alarm

frontend falcon-redis-vip
    bind $VIP:6378
    default_backend falcon-redis

backend falcon-fe
        balance  source
        mode  http
        option  forwardfor
        server $FALCON_A_NAME $FALCON_A:1234 check inter 2000 rise 2 fall 5
        server $FALCON_B_NAME $FALCON_B:1234 check inter 2000 rise 2 fall 5

backend falcon-portal
        balance  source
        mode  http
        option  forwardfor
        server $FALCON_A_NAME $FALCON_A:5050 check inter 2000 rise 2 fall 5
        server $FALCON_B_NAME $FALCON_B:5050 check inter 2000 rise 2 fall 5

backend falcon-dashboard
        balance  source
        cookie  SERVERID insert indirect nocache
        mode  http
        option  forwardfor
        option  httpchk
        option  httpclose
        rspidel  ^Set-cookie:\ IP=
        server $FALCON_A_NAME $FALCON_A:8081 cookie $FALCON_A_NAME check inter 2000 rise 2 fall 5
        server $FALCON_B_NAME $FALCON_B:8081 cookie $FALCON_B_NAME check inter 2000 rise 2 fall 5

backend falcon-query
    balance roundrobin
    mode  http
    option forwardfor
    server $FALCON_A_NAME $FALCON_A:9966 check inter 10s
    server $FALCON_B_NAME $FALCON_B:9966 check inter 10s

backend falcon-hbs
    balance roundrobin
    mode  tcp
    server $FALCON_A_NAME $FALCON_A:6030 check inter 10s
    server $FALCON_B_NAME $FALCON_B:6030 check inter 10s


backend falcon-transfer-http
    balance leastconn
    mode  http
    server $FALCON_A_NAME $FALCON_A:6060 check inter 10s
    server $FALCON_B_NAME $FALCON_B:6060 check inter 10s

backend falcon-transfer
    balance leastconn
    mode  tcp
    server $FALCON_A_NAME $FALCON_A:8433 check inter 10s
    server $FALCON_B_NAME $FALCON_B:8433 check inter 10s
    

backend falcon-alarm
    balance roundrobin
    mode  http
    server $FALCON_A_NAME $FALCON_A:6067 check inter 10s 
    server $FALCON_B_NAME $FALCON_B:6067 check inter 10s backup

backend falcon-redis
    balance roundrobin
    mode  tcp

    option tcp-check
    tcp-check send PING\r\n
    tcp-check expect string +PONG
    tcp-check send QUIT\r\n
    tcp-check expect string +OK
    server $FALCON_A_NAME $FALCON_A:6378 check inter 1s 
    server $FALCON_B_NAME $FALCON_B:6378 check inter 1s backup


EOF

systemctl restart keepalived haproxy 
systemctl enable keepalived haproxy 

netstat -natp | grep haproxy
ip -o -f inet addr show
