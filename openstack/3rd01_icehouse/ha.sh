#!/bin/bash
source ./master/master.conf

sed -i "/net.ipv4.ip_forward/ s/0/1/" /etc/sysctl.conf
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
sed -i "s/net.ipv4.conf.default.rp_filter = 2/net.ipv4.conf.default.rp_filter = 0/" /etc/sysctl.conf > /dev/null
sed -i "s/net.ipv4.conf.all.rp_filter = 2/net.ipv4.conf.all.rp_filter = 0/" /etc/sysctl.conf > /dev/null

sysctl -p

#yum -y install keepalived haproxy
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
    mode http
    maxconn 10000
    timeout connect 300s
    timeout client 300s
    timeout server 300s

frontend horizon-http-vip
    bind $VIP:$HTTP_PORT
    default_backend horizon-http-api

frontend keystone-admin-vip
    bind $VIP:35357
    default_backend keystone-admin-api

frontend keystone-public-vip
    bind $VIP:5000
    default_backend keystone-public-api

frontend glance-vip
    bind $VIP:9191
    default_backend glance-api

frontend glance-registry-vip
    bind $VIP:9292
    default_backend glance-registry-api

frontend neutron-vip
    bind $VIP:9696
    default_backend neutron-api

frontend nova-ec2-vip
    bind $VIP:8773
    default_backend nova-ec2-api

frontend nova-novnc-vip
    bind $VIP:6080
    default_backend nova-novnc-api

frontend nova-compute-vip
    bind $VIP:8774
    default_backend nova-compute-api

frontend nova-metadata-vip
    bind $VIP:8775
    default_backend nova-metadata-api

frontend cinder-vip
    bind $VIP:8776
    default_backend cinder-api

frontend ceilometer-vip
    bind $VIP:8777
    default_backend ceilometer-api

frontend aodh-vip
    bind $VIP:8042
    default_backend aodh-api

frontend heat-vip
    bind $VIP:8004
    default_backend heat-api

frontend heat-cfn-vip
    bind $VIP:8000
    default_backend heat-api-cfn




backend horizon-http-api
        balance  source
        cookie  SERVERID insert indirect nocache
        mode  http
        option  forwardfor
        option  httpchk
        option  httpclose
        rspidel  ^Set-cookie:\ IP=
        server controller01 $MASTER_A:$HTTP_PORT cookie controller01 check inter 2000 rise 2 fall 5
        server controller02 $MASTER_B:$HTTP_PORT cookie controller02 check inter 2000 rise 2 fall 5

backend keystone-admin-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:35357 check inter 10s
    server controller02 $MASTER_B:35357 check inter 10s

backend keystone-public-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:5000 check inter 10s
    server controller02 $MASTER_B:5000 check inter 10s

backend glance-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:9191 check inter 10s
    server controller02 $MASTER_B:9191 check inter 10s

backend glance-registry-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:9292 check inter 10s
    server controller02 $MASTER_B:9292 check inter 10s

backend neutron-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:9696 check inter 10s
    server controller02 $MASTER_B:9696 check inter 10s

backend nova-ec2-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:8773 check inter 10s
    server controller02 $MASTER_B:8773 check inter 10s

backend nova-novnc-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:6080 check inter 10s
    server controller02 $MASTER_B:6080 check inter 10s

backend nova-compute-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:8774 check inter 10s
    server controller02 $MASTER_B:8774 check inter 10s

backend nova-metadata-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:8775 check inter 10s
    server controller02 $MASTER_B:8775 check inter 10s

backend cinder-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:8776 check inter 10s
    server controller02 $MASTER_B:8776 check inter 10s

backend ceilometer-api
    balance roundrobin
    option  forwardfor
    server meter01 $METER_A:8777 check inter 10s
    server meter02 $METER_B:8777 check inter 10s

backend aodh-api
    balance roundrobin
    option  forwardfor
    server meter01 $METER_A:8042 check inter 10s
    server meter02 $METER_B:8042 check inter 10s

backend heat-api
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:8004 check inter 10s
    server controller02 $MASTER_B:8004 check inter 10s

backend heat-api-cfn
    balance roundrobin
    option forwardfor
    server controller01 $MASTER_A:8000 check inter 10s
    server controller02 $MASTER_B:8000 check inter 10s

EOF

systemctl restart keepalived haproxy 
systemctl enable keepalived haproxy 

netstat -natp | grep haproxy
ip -o -f inet addr show
