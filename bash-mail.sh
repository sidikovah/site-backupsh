#!/bin/bash

export PGPASSWORD=''

# Database name
db_name=c_cloud

# Backup storage directory 
backupfolder=/mnt/backup

# Notification email address 
#recipient_email=a.sidikov@p-s.kz

# Number of days to store the backup 
keep_day=5

sqlfile=$backupfolder/c_cloud-database-$(date +%d-%m-%Y_%H-%M-%S).sql
zipfile=$backupfolder/c_cloud-database-$(date +%d-%m-%Y_%H-%M-%S).zip

#create backup folder
mkdir -p $backupfolder

# Create a backup

if pg_dump -U backup -h 10.0.0.0 -p 6432 $db_name > $sqlfile ; then
   echo 'Sql dump created'
else
   echo 'pg_dump return non-zero code' | mailx -s 'No backup was created!' $recipient_email
   exit
fi

# Compress backup 
if gzip -c $sqlfile > $zipfile; then
   echo 'The backup was successfully compressed'
else
   echo 'Error compressing backup' | mailx -s 'Backup was not created!' $recipient_email
   exit
fi

rm $sqlfile 
#echo $zipfile | mailx -s 'Backup was successfully created' $recipient_email

# Delete old backups 
find $backupfolder -mtime +$keep_day -delete
