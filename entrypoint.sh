#!/bin/sh


if [ "$CLUSTER" = "Y" ]; then
 echo "Configuring cluster"

 #WAL (Write Ahead Log) setting
 #change the value to hot_standby.
 sed -i "s/#wal_level = replica/wal_level = hot_standby/g"  /etc/postgresql/${VERSION}/main/postgresql.conf

 #wal sender process
 sed -i "s/#max_wal_senders = 10/max_wal_senders = 3/g"  /etc/postgresql/${VERSION}/main/postgresql.conf
 sed -i "s/#wal_keep_segments = 0/wal_keep_segments = 8/g"  /etc/postgresql/${VERSION}/main/postgresql.conf

 #archive command
 sed -i "s/#archive_mode = off/archive_mode = on/g"  /etc/postgresql/${VERSION}/main/postgresql.conf
 echo "archive_command = 'cp -i %p /var/lib/postgresql/${VERSION}/main/archive/%f'" >>  /etc/postgresql/${VERSION}/main/postgresql.conf

 #change the value to 8.
 #echo 'checkpoint_segments = 8 >> /etc/postgresql/${VERSION}/main/postgresql.conf

 if [ "$IS_SLAVE" = "Y" ]; then
  sed -i "s/#hot_standby = on/ hot_standby = on/g"  /etc/postgresql/${VERSION}/main/postgresql.conf 
 
  #create recovery file
  RECOVERY_PATH=/var/lib/postgresql/${VERSION}/main/recovery.conf
  cat >> ${RECOVERY_PATH}
  echo "standby_mode = 'on'" >> ${RECOVERY_PATH}
  echo "primary_conninfo = 'host=${MASTER_HOST} port=5432 user=replica password=replicauser@'" >> ${RECOVERY_PATH} 
  echo "restore_command = 'cp //var/lib/postgresql/${VERSION}/main/archive/%f %p'" >> ${RECOVERY_PATH}
  echo "trigger_file = '/tmp/postgresql.trigger.5432'" >> ${RECOVERY_PATH}
   
 else
 
  #TODO : add for multiple slave
  echo "configuring slave ips"
  echo "host    replication     replica   $IP_SLAVE/24 md5" >> /etc/postgresql/${VERSION}/main/pg_hba.conf 
 fi

fi
