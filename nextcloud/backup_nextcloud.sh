#!/bin/bash
# Full backup, every day at 3pm
# TODO set maintenance mode on

current_date=$(date +%F_%H:%I:%S)

# ssh string : make sure that SSH key are available, or script will wait for password.
# Also make sure that user has write permissions on destination folder
ssh_details="epsi-backup@192.168.56.104"

# On remote host
backup_directory="/home/epsi-backup/backup/"

# On local host
nextcloud_directory="/var/www/html/nextcloud/"

current_backup=${backup_directory}${current_date}
backup_sql=${current_backup}"/backup.sql"

ssh $ssh_details mkdir -p "${current_backup}"
tar zcvf - "$nextcloud_directory" | ssh ${ssh_details} "cat > ${current_backup}/nextcloud.tar.gz"

# TODO set maintenance mode off