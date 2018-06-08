#!/bin/bash
#sh hosts.sh 10.154.20.0/25

CLUSTER="plato01-tdxy"
REGION="bj-cn"
DOMAIN="vps.letv.cn"


#check read
if [ $# -ne 1 ];then
    echo "Usage: $0 network/prefix, for example: $0 192.168.1.0/24"
    exit 1
fi
NETWORK=$1

#check IP:
if ! ipcalc -bn $NETWORK>/dev/null;then
    exit 1
fi

#get iplit
n=($(ipcalc -bn $NETWORK |awk -F'[=.]' '{printf $2*256^3+$3*256^2+$4*256+$5" "}'))
for IP in `seq $[${n[1]}+1] $[${n[0]}-1] |awk -vOFS=. '{i=$0;print int(i/256^3),int(i%256^3/256^2),int(i%256^3%256^2/256),i%256^3%256^2%256}'`
do
IP_C=`echo $IP | cut -d "." -f 3`
IP_D=`echo $IP | cut -d "." -f 4`
HOST_NAME="c-${IP_C}-${IP_D}-${CLUSTER}.${REGION}.${DOMAIN}"
HOST_SNAME="c-${IP_C}-${IP_D}-${CLUSTER}"
echo $IP $HOST_NAME $HOST_SNAME
done
