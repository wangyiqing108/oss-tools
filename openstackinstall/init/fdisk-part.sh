#!/bin/sh
umount /letv
mkfs -t ext4 -m 1 /dev/mapper/VGSYS-lv_letv
mount -a
rm -rf /letv/lost+found
mkdir -p /letv/openstack
df -h