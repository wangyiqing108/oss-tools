#!/bin/bash
fping_test() {
   fping -g $1 -a -t 500 >> $2 &
}
if [ ! $1 ];then
   echo 'fping_test ipfile'
else
   logfile="fping_test_`date +%Y-%m-%d-%H:%M:%S`.log"
   for ips in `cat $1`;do
      fping_test $ips /tmp/$logfile
   done
fi

echo 'fping test begin ...'
while true
do
   if [ `ps aux|grep 'fping -g'|grep 't 500'|grep -v grep|wc -l` != "0" ];then
      sleep 1
   else
      cat /tmp/$logfile |sort > $logfile
      echo "alive ip num: `cat $logfile|wc -l`"
      echo "log name: $logfile"
      echo 'fping test finished ...'
      exit 1
   fi
done
