#!/bin/bash

usage ()
{

  echo "usage: resize_vm.sh <instance_uuid> <flavor_id>"
}
if [ $# -ne 2 ]; then
  usage
  exit -1
fi
CONN=`cat /etc/nova/nova.conf|grep -v "^#"|grep connection`
TMPLOGIN=`echo $CONN|cut -d"/" -f3|cut -d"@" -f1`
USERNAME=`echo $TMPLOGIN|cut -d":" -f1`
PASSWORD=`echo $TMPLOGIN|cut -d":" -f2`
TMPHOST=`echo $CONN|cut -d"/" -f3|cut -d"@" -f2`
HOST=`echo $TMPHOST|cut -d":" -f1`
PORT=`echo $TMPHOST|cut -d":" -f2`
NOVADB=`echo $CONN|cut -d"/" -f4`
[ -z "$PORT" ] && PORT=3306


DBUSER=$USERNAME
DBPASS=$PASSWORD
DBNAME=$NOVADB
DBPORT=$PORT
DBHOST=$HOST

INSTANCE_UUID=$1
FLAVORID=$2
#mysql -h mysqlserver -P 3842 -unova -pf77463fb8a
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME << EOF
update instances set instance_type_id=(select id from instance_types where flavorid="$FLAVORID" and deleted_at is NULL) where uuid="$INSTANCE_UUID";
update instance_system_metadata set value="$FLAVORID" where instance_uuid="$INSTANCE_UUID" and \`key\`='instance_type_flavorid';
EOF

. /root/.bash_profile
nova reboot --hard $INSTANCE_UUID
