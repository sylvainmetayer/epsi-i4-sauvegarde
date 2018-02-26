#!/bin/bash
# shellcheck disable=2029
# shellcheck disable=2069

# make sure that SSH key are available, or script will wait for password.
# Also make sure that user has write permissions on destination folder
SSH_DETAILS="epsi-nextcloud@192.168.56.101"
BACKUP_LOCATION="/home/user"
RESTAURATION_LOCATION="/home/user/test"

# Do not edit below
CURRENT_DATE=$(date +%s)
LOG_FILE="/tmp/restore_${CURRENT_DATE}.log"

clear
exec 2>&1 &> >(tee "${LOG_FILE}")
echo "$LOG_FILE"

while :
do
    echo "Which one to restore ? (ctrl-c to quit)"
    iterator=0
    for file in ${BACKUP_LOCATION}/*; do
        iterator=$((iterator + 1))
        echo -n "${iterator} - "
        if test -d "$file"; then
            echo "Restore last incremental backup"
        else 
            filename=$(basename "$file")
            format_date=$(date -d @"${filename%%.*}")
            echo "$format_date"
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
    iterator=$((iterator + 1))
    if [[ $user_choice -eq $iterator ]]; then 
        restauration_file=$file
    fi
done

ssh $SSH_DETAILS rm -rf "$RESTAURATION_LOCATION && mkdir -p $RESTAURATION_LOCATION"
if test -f "$restauration_file"; then
    filename=$(basename "$restauration_file")
    echo "I will restore $restauration_file"
    scp "$restauration_file" "${SSH_DETAILS}:${RESTAURATION_LOCATION}/"
    ssh $SSH_DETAILS "tar xf ${RESTAURATION_LOCATION}/$filename -C ${RESTAURATION_LOCATION} && rm -f ${RESTAURATION_LOCATION}/$filename"
else 
    echo "I will restore last incremental backup : $file"
    scp -r "${restauration_file}"/* ${SSH_DETAILS}:${RESTAURATION_LOCATION}
fi

echo "Restauration successful !"

# TODO Database restauration