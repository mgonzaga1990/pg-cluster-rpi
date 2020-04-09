#!/bin/sh


#SET Listener Address
echo "listen_addresses='*'" >> ${CONFIG_PATH}/postgresql.conf


# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/${VERSION}/main/pg_hba.conf


# Validate Cluster settings (if any)
if [ ! -f "/usr/bin/cluster.properties" ]; then
 echo "No clustering setup found"
else
 echo "Clustering setup file found!"
  while IFS='=' read -r key value
  do
    key=$(echo $key | tr '.' '_')
    eval ${key}=\${value}
  done < "/usr/bin/cluster.properties"
  
  if [ "$CLUSTER" = "Y" ]; then
   echo "UPDATING postgresql.conf file"
   #WAL (Write Ahead Log) setting
   echo "setting wal_level to host_standby"
   sed -i "s/#wal_level = replica/wal_level = hot_standby/g"  /etc/postgresql/${VERSION}/main/postgresql.conf

   #wal sender process
   echo "setting max_wal_senders to 3"
   sed -i "s/#max_wal_senders = 10/max_wal_senders = 3/g"  /etc/postgresql/${VERSION}/main/postgresql.conf
   echo "setting wal_keep_segments to 8"
   sed -i "s/#wal_keep_segments = 0/wal_keep_segments = 8/g"  /etc/postgresql/${VERSION}/main/postgresql.conf

   #archive command
   echo "setting archive_mode to on"
   sed -i "s/#archive_mode = off/archive_mode = on/g"  /etc/postgresql/${VERSION}/main/postgresql.conf
   echo "archive command = 'cp -i %p /var/lib/postgresql/${VERSION}/main/archive/%f'"
   echo "archive_command = 'cp -i %p /var/lib/postgresql/${VERSION}/main/archive/%f'" >>  /etc/postgresql/${VERSION}/main/postgresql.conf

   #change the value to 8.
   #echo 'checkpoint_segments = 8 >> /etc/postgresql/${VERSION}/main/postgresql.conf

   if [ "$IS_SLAVE" = "Y" ]; then
    echo "Setup detected to be slave"
    echo "setting hot_standby to on"
    sed -i "s/#hot_standby = on/ hot_standby = on/g"  /etc/postgresql/${VERSION}/main/postgresql.conf 
 
    #create recovery file
    echo "Creating recovery.conf file in /var/lib/postgresql/${VERSION}/main"
    RECOVERY_PATH=/var/lib/postgresql/${VERSION}/main/recovery.conf
    cat >> ${RECOVERY_PATH}
    echo "standby_mode = 'on'" >> ${RECOVERY_PATH}
    echo "primary_conninfo = 'host=${MASTER_HOST} port=5432 user=replica password=replicauser@'" >> ${RECOVERY_PATH} 
    echo "restore_command = 'cp //var/lib/postgresql/${VERSION}/main/archive/%f %p'" >> ${RECOVERY_PATH}
    echo "trigger_file = '/tmp/postgresql.trigger.5432'" >> ${RECOVERY_PATH}
   else
    echo "Setup detected to be the master"
    #TODO : add for multiple slave
    echo "configuring slave ips[$IP_SLAVE]"
    echo "host    replication     replica   $IP_SLAVE/24 md5" >> /etc/postgresql/${VERSION}/main/pg_hba.conf 
   fi
  fi
fi


###START POSTGRE DB
exec /usr/lib/postgresql/10/bin/postgres -D /var/lib/postgresql/10/main -c config_file=/etc/postgresql/10/main/postgresql.conf
