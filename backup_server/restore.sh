#!/bin/bash

#rsync -e ssh -azp -vvv /var/www/html/nextcloud/data/ epsi-backup@192.168.56.104:~/nextcloud-files/$(date +%F--%H:%I:%S)

# VARIABLES

nextcloud_directory="/var/www/html/nextcloud"

backup_directory="/home/epsi-backup/backup/"
files_directory="nextcloud"
sql_filename="backup.sql"

declare -A ERRORS=( [NO_BACKUP]=0 ) 

restore_last_daily_backup() {
    files=/tmp/$$

    for file in $backup_directory/*
    do
        if [ -d $file ]; then
            echo "${file##*/}" >> $files
        fi
    done

    if [ -f "$files" ]; then 
        sort -r $files -o $files
        folder_to_restore=$(head -n1 $files)
        echo "TODO Restore ${folder_to_restore}"
        # TODO
    else
        echo "Their is no backup to restore."
        exit "${ERRORS[NO_BACKUP]}"
    fi
    
}

menu() {
    echo "------------"
    echo "Which to restore ?"
    echo "0- Current (might be unstable as it is synchronised every hour)"
    echo "1- Last daily backup"
    echo "------------"
    echo -n "Your choice :"
}

menu
while :
do
  read -r INPUT_STRING
  case $INPUT_STRING in
	0)
		echo "Not implemented yet, come back later."
        exit 1
    	;;
	1)
        restore_last_daily_backup
        # TODO restauration went well ? 
		;;
	*)
        echo "Error, retry."
        menu
    	;;
  esac
done

