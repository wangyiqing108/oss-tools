ip_net='10.11.108.%'
master_ip='10.11.108.201'


for port in 3306 3307 3308;do
master_data=`mysql -S /letv/$port/tmp/mysql.sock <<EOF
grant replication slave on *.* to  'rep1'@"${ip_net}" identified by 'rep1JH3bd32df';
flush privileges;
flush tables with read lock;
show master status;
EOF`
master_log_file=`echo $master_data|awk '{print $5}'`
master_log_pos=`echo $master_data|awk '{print $6}'`


slave_sql="stop slave;CHANGE MASTER TO MASTER_HOST=\'${master_ip}\',MASTER_PORT=$port,MASTER_USER='rep1',MASTER_PASSWORD='rep1JH3bd32df',MASTER_LOG_FILE=\'${master_log_file}\',MASTER_LOG_POS=${master_log_pos};start slave;show slave status\G"

slave_cmd="/usr/local/mariadb/bin/mysql -S /letv/$port/tmp/mysql.sock -e \"$slave_sql\""
echo $slave_cmd
done

#UNLOCK TABLES;
