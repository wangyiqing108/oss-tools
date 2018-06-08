#!/bin/bash
source ./master.conf
cluster=$(hostname -s|awk -F - '{print $4"-"$5}')
tenant_id=\'$(keystone tenant-list|grep manager|awk '{print $2}')\'
nei_id=$(echo $nei_network|awk -F . '{print $3}')
wai_id=$(echo $wai_network|awk -F . '{print $3}')

echo "neutron net-create ${cluster}_vlan_nei --provider:network_type=vlan --tenant-id=${tenant_id} --provider:physical_network=physnet1  --provider:segmentation_id=$nei_vlan
neutron subnet-create --name=private_${nei_id} ${cluster}_vlan_nei ${nei_network} --tenant-id=${tenant_id}  --ip-version 4 --gateway ${nei_gateway} --allocation-pool start=${nei_start_ip},end=${nei_end_ip} --dns-nameserver 10.200.0.3 --dns-nameserver 219.141.136.10 --disable-dhcp

neutron net-create ${cluster}_vlan_wai --provider:network_type=vlan --tenant-id=${tenant_id} --provider:physical_network=physnet1  --provider:segmentation_id=$wai_vlan
neutron subnet-create --name=public_${wai_id} ${cluster}_vlan_wai ${wai_network}  --tenant-id=${tenant_id}  --ip-version 4 --gateway ${wai_gateway} --allocation-pool start=${wai_start_ip},end=${wai_end_ip} --dns-nameserver 10.200.0.3 --dns-nameserver 219.141.136.10 --disable-dhcp"
