#!/bin/bash
# count arp ntable_entries router_count
time_today=$(date +%Y%m%d)
time_yesterday=$(date -d"-1 day" +%Y%m%d)
time_min=$(date +%H:%M)
log_dir="/letv/arp_log"

while true;do
    time_sec=$(date +%H:%M:%S)
    arp_count=$(arp -n | wc -l)
    ntable_entries=$(ip -4 -s ntable show|grep entries|awk -F 'entries ' '{print $2}'|head -n1)
    router_count=$(netstat -rCn|awk '{print $3}'|sort |uniq |wc -l)
    test -d $log_dir || mkdir $log_dir
    test -f "$log_dir/arp_${time_yesterday}" && rm -fr $log_dir/arp_${time_yesterday}
    echo "$time_sec: $arp_count, $ntable_entries,$router_count" >> $log_dir/arp_${time_today}
    sleep 1
done
