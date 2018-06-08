#!/bin/bash

source ./master.conf

#remove letv repo
mv /etc/yum.repos.d/letv-pkgs.repo /etc/yum.repos.d/letv-pkgs.repo_bak

#add openstack repo
rpm -ivh $OPENSTACK_REPO

#glusterfs
yum -y install glusterfs-server

#HA
yum -y install keepalived haproxy 

#MQ
yum -y install rabbitmq-server

#Tools
yum -y install openstack-utils memcached mysql

#keystone
yum -y install openstack-keystone python-keystoneclient

#glance
yum -y install openstack-glance

#nova
yum -y install openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler

# yum -y install openstack-nova-compute

#dashboard
yum -y install openstack-dashboard python-django-horizon

#neutron
yum -y install openstack-neutron-openvswitch openstack-neutron openstack-neutron-ml2 python-neutronclient
