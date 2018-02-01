#!/bin/bash
# shellcheck disable=SC2029 

###############################
#
# Full backup, every day at 3pm
# TODO set maintenance mode on
#
##############################

####################
# make sure that SSH key are available, or script will wait for password.
# Also make sure that user has write permissions on destination folder
ssh_details="epsi-backup@192.168.56.104"

# On remote host, where all are stored.
backup_directory="/home/epsi-backup/backup/"

# On local host
nextcloud_directory="/var/www/html/nextcloud/"

file_archive_name="nextcloud"
sql_file_name="backup.sql"
####################

####################
# DO NOT EDIT BELOW
###################

# Dynamic variables
current_date=$(date +%F_%H:%M:%S)
current_backup=${backup_directory}${current_date}
backup_sql=${current_backup}"/${sql_file_name}"

echo "${current_date} : Going to perform a full backup of the Nextcloud application."
echo "Backup will be located at ${ssh_details}:${current_backup}"

ssh $ssh_details mkdir -p "${current_backup}"
cd $nextcloud_directory && tar zcf - . | ssh ${ssh_details} "cat > ${current_backup}/${file_archive_name}.tar.gz"

echo "Files backed up ! Going to perform a backup of the database."

# TODO set maintenance mode off