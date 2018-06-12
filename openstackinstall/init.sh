#!/bin/bash
test -d /letv/openstack/nova/ && echo 'openstack node already init' && exit 1
#icehouse-6.0
#icehouse-5.0(4.1)
#havana
openstack_release=$1
if [ ! $openstack_release ];then
    exit 1
elif [ $openstack_release != 'icehouse-6.0' -a $openstack_release != 'icehouse-5.0' -a $openstack_release != 'icehouse-4.1' -a $openstack_release != 'havana' ];then
    echo "icehouse-6.0 or icehouse-5.0 or havana"
    exit 1
else 
    :
fi

#wget -P /root/.ssh/ http://115.182.93.170:8080/Tools/ssh_key/hosts.key
wget -P /root/.ssh/ http://115.182.93.170:8080/Tools/ssh_key/hosts.key
cat /root/.ssh/hosts.key >> /root/.ssh/authorized_keys
rm -rf /root/.ssh/hosts.key
echo Myiaas.chensh.net | passwd --stdin root
if [ $(grep -c "sshd:10.112." /etc/hosts.allow) == '0' ];then
cat >> /etc/hosts.allow << EOF
sshd:10.104.28.116
sshd:10.204.
sshd:10.182.
sshd:117.121.58.68
sshd:10.58.102.210
sshd:10.154.
sshd:10.120.
sshd:10.121.
sshd:10.176.
sshd:10.135.
sshd:10.142.
sshd:10.130.152.
sshd:10.180.160.
sshd:10.150.195.
sshd:10.11.140.
sshd:10.185.
sshd:10.118.
sshd:10.11.143.
sshd:10.104.
sshd:10.112.
sshd:10.100.150.
sshd:10.130.150.
sshd:10.180.150.
sshd:123.126.33.253
sshd:10.58.104.129
sshd:10.58.100.128
sshd:117.121.2.119
#Jump Boxes
sshd:115.182.51.252 
sshd:115.182.51.29
sshd:10.182.192.118  
sshd:10.182.192.145 
sshd:10.182.63.226

#Bastion Hosts
sshd:117.121.53.254
sshd:117.121.54.78
sshd:115.182.92.254

#Zabbix Boxes
sshd:/etc/zabbix_hosts_allow
sshd:/etc/services_hosts_allow
EOF
fi
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak
mv /etc/yum.repos.d/CentOS.repo /etc/yum.repos.d/CentOS.repo_bak
mv /etc/yum.repos.d/letv-pkgs.repo /etc/yum.repos.d/letv-pkgs.repo_bak
mv /etc/yum.repos.d/CentOS-Vault.repo /etc/yum.repos.d/CentOS-Vault.repo_bak
for i in `find /etc/yum.repos.d/ -name "*.repo"`
do 
    mv $i /tmp
done
rpm -e axel
rpm -e virt-top-1.0.4-3.15.el6.x86_64
rpm -e libvirt-client-0.10.2-46.el6_6.3.x86_64
find /etc/yum.repos.d/ -name "*.repo"

if [ "$openstack_release" == 'icehouse-6.0' ];then
    rpm -ivh http://115.182.93.170/repo/letv-rdo-release-icehouse-6.0.noarch.rpm --force
    if [ "$(cat /etc/issue|egrep "Controller|master"|wc -l)" == "1" ];then
        yum -y install glusterfs-server rabbitmq-server keepalived haproxy memcached mysql python-novaclient-2.17.0-3.el6.noarch python-nova-2014.1.3-15.el6.noarch openstack-nova-novncproxy-2014.1.3-15.el6.noarch openstack-keystone-2014.1.4-10.el6.noarch python-keystoneclient-0.9.0-1.el6.noarch python-django-horizon-2014.1.4-11.el6.noarch openstack-nova-scheduler-2014.1.3-15.el6.noarch openstack-nova-console-2014.1.3-15.el6.noarch openstack-nova-api-2014.1.3-15.el6.noarch openstack-glance-2014.1.3-11.el6.noarch openstack-neutron-2014.1.4-14.el6.noarch openstack-neutron-ml2-2014.1.4-14.el6.noarch openstack-dashboard-2014.1.3-12.el6.noarch python-neutronclient-2.3.4-10.el6.noarch openstack-utils-2014.1-3.1.el6.noarch openstack-nova-conductor-2014.1.3-15.el6.noarch openstack-neutron-openvswitch-2014.1.4-14.el6.noarch python-django-openstack-auth-1.1.7-4.el6.noarch
        #yum -y install glusterfs-server rabbitmq-server keepalived haproxy openstack-utils memcached mysql openstack-keystone python-keystoneclient openstack-glance openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler openstack-dashboard-2014.1.3-12.el6.noarch python-django-openstack-auth-1.1.5-1.el6.noarch openstack-neutron-openvswitch-2014.1.4-14.el6.noarch openstack-neutron-2014.1.4-14.el6.noarch openstack-neutron-ml2-2014.1.4-14.el6.noarch python-neutronclient-2014.1.4-14.el6.noarch openstack-nova-console
        yum -y install libguestfs-tools-c
    elif [ "$(cat /etc/issue|egrep "Compute|node"|wc -l)" == "1" ];then
        yum -y install libvirt-client-0.10.2-200.el6.89.letv.x86_64 qemu-kvm-0.12.1.2-2.415.el6.89.x86_64 libvirt-0.10.2-200.el6.89.letv.x86_64 virt-top-1.0.4-3.15.el6.x86_64 libvirt-python-0.10.2-200.el6.89.letv.x86_64 openstack-neutron-2014.1.4-14.el6.noarch openstack-neutron-ml2-2014.1.4-14.el6.noarch openstack-neutron-openvswitch-2014.1.4-14.el6.noarch openstack-nova-compute-2014.1.3-15.el6.noarch openstack-utils-2014.1-3.1.el6.noarch python-keystoneclient-0.9.0-1.el6.noarch
        #yum -y install qemu-kvm libvirt virt-top openstack-utils openstack-nova-compute  python-neutron-2014.1.4-14.el6.noarch openstack-neutron-2014.1.4-14.el6.noarch openstack-neutron-openvswitch-2014.1.4-14.el6.noarch openstack-neutron-ml2-2014.1.4-14.el6.noarch
    fi
elif [ "$openstack_release" == 'icehouse-5.0' ];then
    rpm -e letv-rdo-release-icehouse-4.1.noarch
    rpm -e letv-rdo-release-icehouse-5.0.noarch
    rpm -ivh http://115.182.93.170/repo/letv-rdo-release-icehouse-6.0.noarch.rpm --force
    if [ "$(cat /etc/issue|egrep "Compute|node"|wc -l)" == "1" ];then
        yum -y install qemu-kvm libvirt virt-top openstack-utils openstack-nova-compute-2014.1.3-13.el6.noarch  python-neutron-2014.1.4-11.el6.noarch openstack-neutron-2014.1.4-11.el6.noarch openstack-neutron-openvswitch-2014.1.4-11.el6.noarch openstack-neutron-ml2-2014.1.4-11.el6.noarch
    fi
elif [ "$openstack_release" == 'icehouse-4.1' ];then
    rpm -e letv-rdo-release-icehouse-4.1.noarch
    rpm -e letv-rdo-release-icehouse-5.0.noarch
    rpm -ivh http://115.182.93.170/repo/letv-rdo-release-icehouse-6.0.noarch.rpm --force
    if [ "$(cat /etc/issue|egrep "Compute|node"|wc -l)" == "1" ];then
        yum -y install libvirt-0.10.2-29.el6.88.x86_64 qemu-kvm-0.12.1.2-2.415.el6.89.x86_64 openstack-neutron-2014.1.3-14.el6.noarch openstack-neutron-ml2-2014.1.3-14.el6.noarch openstack-neutron-openvswitch-2014.1.3-14.el6.noarch openstack-nova-compute-2014.1.3-13.el6.noarch openstack-utils-2014.1-3.1.el6.noarch python-keystoneclient-0.9.0-1.el6.noarch python-memcached-1.53-1.el6.noarch python-neutronclient-2.3.4-10.el6.noarch 
    fi
elif [ "$openstack_release" == 'havana' ];then
    rpm -ivh http://115.182.93.170/repo/letv-rdo-release-havana-10.0.noarch.rpm --force
    if [ "$(cat /etc/issue|egrep "Compute|node"|wc -l)" == "1" ];then
        :
        #yum install  libvirt libvirt-client  virt-top openstack-utils openstack-nova-compute-2013.2.3-10* openstack-nova-common-2013.2.3-10* openstack-nova-network-2013.2.3-10* -y
    fi
fi
echo "rpm install finished"

# lldp
yum install libconfig lldpad lldpad-libs -y
/etc/init.d/lldpad restart
chkconfig lldpad on
if [ ! -f "/bin/show-switchport" ];then
   wget -P /bin/ http://openstack.oss.letv.cn:8080/Tools/network/lldp/show-switchport
fi
chmod 755 /bin/show-switchport
echo "lldp install finished"

# format
if [ ! -d "/letv/openstack" ];then
    umount /letv
    mkfs -t ext4 -m 1 /dev/mapper/VGSYS-lv_letv
    mount -a
    rm -rf /letv/lost+found
    mkdir -p /letv/openstack
    ls /letv
else
    echo "format is already finished"
fi

# optimize
if [ -f "/etc/.Tools/scripts/setirq" ];then
    /etc/.Tools/scripts/setirq -a -d -q
    if [ "$(cat /etc/rc.local|grep setirq|wc -l)" == "0" ];then
        echo '/etc/.Tools/scripts/setirq -a -d -q' >> /etc/rc.local
    fi
fi

