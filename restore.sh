#!/bin/bash

# make sure that SSH key are available, or script will wait for password.
# Also make sure that user has write permissions on destination folder
SSH_DETAILS="epsi-nextcloud@192.168.56.101"
BACKUP_LOCATION="/home/user"
BASENAME_BACKUP="archive" # .$(date).tar

# Do not edit below
CURRENT_DATE=$(date +%F__%H_%M_%S)
LOG_FILE="/tmp/restore_${CURRENT_DATE}.log"
my_true=true
my_false=false

# shellcheck disable=2069
exec 2>&1 &> >(tee "${LOG_FILE}")
echo "$LOG_FILE"

while :
do
    echo "Which one to restore ? (ctrl-c to quit)"
    iterator=0
    for file in ${BACKUP_LOCATION}/*; do
        if [[ -d $file ]]; then
            # TODO Here indicate how many incremental + complete are present in folder (1 complete max, N incremntal)
            iterator=$((iterator + 1))
            echo "${iterator} - $file"
        fi
    done
    
    iterator_max=$iterator
    echo -n "Your choice : "
    read -r user_choice
    
    if [[ ! $user_choice =~ ^[0-9]+$ ]]; then
        echo "Not a number. Try again."
        continue
    fi

    if [[ "$user_choice" -lt 1 || "$user_choice" -gt "$iterator_max" ]]; then
        echo "Not a valid choice. Try again."
    else
        break
    fi
done

iterator=0
for file in ${BACKUP_LOCATION}/*; do
    if [[ -d $file ]]; then
        iterator=$((iterator + 1))
        if [[ $user_choice -eq $iterator ]]; then 
            current_folder=$file
        fi
    fi
done

iterator=0
for file in ${BACKUP_LOCATION}/$(basename "${current_folder}")/${BASENAME_BACKUP}.*.tar.gz; do
    iterator=$((iterator + 1))
    if [[ $iterator -eq 1 ]]; then
        echo "I will restore complete $file"
    else 
        echo "Now that I have restore a complete, I will restore a incremental one."
        echo "$file"
    fi
done

# TODO Restore snippet
#ssh $SSH_DETAILS rm -rf "$nextcloud_directory" && mkdir -p "$nextcloud_directory"
# Upload tar
#scp "${backup_directory}$archive" "${SSH_DETAILS}:${nextcloud_directory}"
# Untar and remove archive file
#ssh $SSH_DETAILS tar xf "${nextcloud_directory}/$archive" && rm "${nextcloud_directory}/$archive"