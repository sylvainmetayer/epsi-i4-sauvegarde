#!/bin/bash
# shellcheck disable=SC2029 

###############################
#
# Restauration from a full backup or current one.
#
##############################

####################
# make sure that SSH key are available, or script will wait for password.
# Also make sure that user has write permissions on destination folder
ssh_details="epsi-backup@192.168.56.103"

# On local host, where all backup are stored.
backup_directory="/home/epsi-backup/backup/"

# On remote host, where we should restore the nextcloud application.
nextcloud_directory="/var/www/html/nextcloud"

file_archive_name="nextcloud"
sql_filename="backup.sql"
####################

####################
# DO NOT EDIT BELOW
###################
declare -A ERRORS=( [NO_BACKUP]=1 [CD_FAILS]=2 ) 

restore_folder_daily_backup() {
    if [ $# -ne 1 ]; then
        echo "Folder name is required."
    fi

    echo "Going to restore $1"

    cd "${backup_directory}${1}" || exit "${ERRORS[CD_FAILS]}"
    ls

    # TODO set maintenance mode on
    # First, remove everything that could exist before and create folder.
    ssh $ssh_details rm -rf "$nextcloud_directory" && mkdir -p "$nextcloud_directory"
    # Upload tar
    scp "${backup_directory}$1" "${ssh_details}:${nextcloud_directory}"

    # Untar and remove archive file
    ssh $ssh_details tar xf "${nextcloud_directory}/$1" && rm "${nextcloud_directory}/$1"

    # TODO set maintenance mode off

}

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

show_errors() {
    echo "--------------------"
    echo "Want to know about return code provided by this script ?"
    echo "0 - All good, no errors"
    echo "1 - Their is no backup to restore !"
    echo "2 - 'cd' fails. Maybe a permission issue ?"
    echo "--------------------"
}

while :
do
  menu
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
    2)
        show_errors
        ;;
	*)
        echo "Error, retry."
    	;;
  esac
done
