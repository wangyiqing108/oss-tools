#!/bin/bash
openstack_release='pub-mitaka-2.0'
CLUSTER="lcs"
REGION="cn-test-1"
DOMAIN="i-lecloud.com"
HYPERVISOR_NETWORK="10.11.108.0/24"
LinuxRelease=$(cat /etc/redhat-release |grep -o "[0-9]"|head -n1)
SaltMaster_1="salt-240-197.cn-test-1.lcs.i-lecloud.com"
SaltMaster_2="salt-240-198.cn-test-1.lcs.i-lecloud.com"
HYPERVISOR_NETWORK_BASE=$(echo $HYPERVISOR_NETWORK | cut -d "." -f 1-3)
function 01_openstack_dir() {
if [ ! -d "/letv/openstack" ];then
    rm -rf /letv/lost+found
    mkdir -p /letv/openstack
    ls /letv
else
    echo "01_openstack_dir is already finished"
fi
}

function 02_ssh_allow() {
if [ ! -f "/root/.ssh/id_rsa" ];then
# Openstack ssh key
wget -P /root/.ssh/ http://123.59.176.250:8080/Tools/ssh_key/hosts.key
cat /root/.ssh/hosts.key >> /root/.ssh/authorized_keys
rm -fr /root/.ssh/hosts.key
# Ceph ssh key
wget -P /root/.ssh/ http://123.59.176.250:8080/Tools/ssh_key/ceph_id_rsa.tar.gz
cd /root/.ssh/;tar xfz ceph_id_rsa.tar.gz
rm -fr /root/.ssh/ceph_id_rsa.tar.gz
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzq2t05EhoS53N3kh1CW7LsUfYReuk62S1cAREwB0giqz2Z665TGdcP32HC49bAoudi8m43Zg42rjk+ezlWcVm9gCONphqaDu1KZXSeOj7BR6Ffket9rULaxWQQzo98SLHU8UBp8F4rhieZN2ZXOu1tagOQNZBEJSvpf+oaKIie+7eZIJGKEu0nv6Mx/rRcNoi6J6APynQXL785Yae6RXl3RPfVe+tjAFxz//Yn2olSObikTcRS9fJfpcnnP93WwRXHT0mVLutvvBWEl+U5J5g3W3WleHRASfjtTXvrVEz96krEAyD7P2FmDzO0IE8AXoBSnTg9DKGowuuLIzla1nDQ==' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/id_rsa
chmod 644 /root/.ssh/id_rsa.pub
chown root.root /root/.ssh/id_rsa
chown root.root /root/.ssh/id_rsa.pub

echo Myiaas.chensh.net | passwd --stdin root
cat > /etc/hosts.allow << EOF
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
echo "{$HYPERVISOR_NETWORK_BASE}." >> /etc/services_hosts_allow
echo "02_ssh_allow is finished"
else
    echo "02_ssh_allow is finished"
fi
}

function 03_check() {
echo "===== issue and hostname" > /tmp/init.log
cat /etc/issue|head -n1 >> /tmp/init.log
hostname >> /tmp/init.log
echo "===== ping mirrors.vps.letv.cn" >> /tmp/init.log
ping -A -c 1 mirrors.vps.letv.cn|grep loss >> /tmp/init.log
echo "===== ifconfig br0" >> /tmp/init.log
ifconfig br0 >> /tmp/init.log
echo "===== show-switchport all" >> /tmp/init.log
/bin/show-switchport all >> /tmp/init.log
echo "===== hwconfig" >> /tmp/init.log
hwconfig >> /tmp/init.log
cat /tmp/init.log
systemctl start ntpd
systemctl enable ntpd
}

function 04_host() {
cp -fr /etc/hosts /etc/hosts_bak
cat > /etc/hosts << EOF
127.0.0.1  localhost localhost.localdomain localhost4 localhost4.localdomain4
::1     localhost localhost.localdomain localhost6 localhost6.localdomain6
10.11.108.201 controller-108-201.$REGION.$CLUSTER.$DOMAIN
10.11.108.202 controller-108-202.$REGION.$CLUSTER.$DOMAIN
10.11.108.211 controller-108-211.$REGION.$CLUSTER.$DOMAIN
10.11.108.212 controller-108-212.$REGION.$CLUSTER.$DOMAIN
10.11.108.221 network-108-221.$REGION.$CLUSTER.$DOMAIN
10.11.108.222 network-108-222.$REGION.$CLUSTER.$DOMAIN
10.11.108.231 network-108-231.$REGION.$CLUSTER.$DOMAIN
10.11.108.232 network-108-232.$REGION.$CLUSTER.$DOMAIN
10.58.240.197 salt-240-197.$REGION.$CLUSTER.$DOMAIN
10.58.240.198 salt-240-198.$REGION.$CLUSTER.$DOMAIN
EOF

NETWORK=$HYPERVISOR_NETWORK

#check IP:
if ! ipcalc -bn $NETWORK>/dev/null;then
    exit 1
fi

#get iplit
n=($(ipcalc -bn $NETWORK |awk -F'[=.]' '{printf $2*256^3+$3*256^2+$4*256+$5" "}'))
for IP in `seq $[${n[1]}+10] $[${n[0]}-56] |awk -vOFS=. '{i=$0;print int(i/256^3),int(i%256^3/256^2),int(i%256^3%256^2/256),i%256^3%256^2%256}'`
do
IP_C=`echo $IP | cut -d "." -f 3`
IP_D=`echo $IP | cut -d "." -f 4`
HOST_NAME="compute-${IP_C}-${IP_D}.${REGION}.${CLUSTER}.${DOMAIN}"
HOST_SNAME="compute-${IP_C}-${IP_D}-${CLUSTER}"
echo $IP $HOST_NAME $HOST_SNAME >> /etc/hosts
done

# CentOS 6
if [ $LinuxRelease == "6" ]; then
  HOSTNAME=`cat /etc/hosts|grep -v mysqlserver | grep -w $(ifconfig br0 | grep "inet addr" | awk '{print $
2}' | cut -d ":" -f 2) | awk '{print $2}'`
  hostname $HOSTNAME
  sed -i "/^HOSTNAME/d" /etc/sysconfig/network
  echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
# CentOS 7
elif [ $LinuxRelease == "7" ]; then
  HOSTNAME=`cat /etc/hosts|grep -v mysqlserver | grep -w $(ifconfig br0 | grep "inet" | awk '{print $2}' |
 cut -d ":" -f 2) | awk '{print $2}'`
  hostname $HOSTNAME
  sed -i "/^HOSTNAME/d" /etc/sysconfig/network
  echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
  hostnamectl set-hostname $HOSTNAME
fi
more /etc/sysconfig/network
}

function 05_salt_minion() {
install_rdo
yum install salt-minion -y
yum upgrade salt-minion -y
hostname_num=$(hostname|grep -c "$REGION.$CLUSTER.$DOMAIN")
if [[ $hostname_num == "1" ]];then
cat > /etc/salt/minion << EOF
master: 
  - $SaltMaster_1
  - $SaltMaster_2
pki_dir: /etc/salt/pki/minion
EOF

echo $(hostname) > /etc/salt/minion_id
fi
service salt-minion restart


}

function install_rdo() {
if [ "$openstack_release" == 'pub-icehouse-2.0' ];then
yum install http://10.110.176.250/repo/letv-rdo-release-mitaka-pub-1.0-2.el7.x86_64.rpm -y
echo "rpm install finished"
fi
}

function main() {
01_openstack_dir
02_ssh_allow
03_check
04_host
05_salt_minion
}

if [ -n "$1" ]; then
    case "$1" in
    -c) 03_check;;
    -S) 02_ssh_allow;;
    -s) 05_salt_minion;;
    -H) 04_host;;
    -h) echo -e "-c: 03_check\n-S: 02_ssh_allow\n-s: 05_salt_minion\n-H: 04_host";;
    esac
else
    main $@
fi
