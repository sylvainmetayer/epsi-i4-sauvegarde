#!/bin/bash

# make sure that SSH key are available, or script will wait for password.
# Also make sure that user has write permissions on destination folder
SSH_DETAILS="epsi-backup@192.168.56.102"
BACKUP_DIR="/var/www/nextcloud/"
BACKUP_LOCATION="/home/epsi-backup/backup/"
BASENAME_BACKUP="backup_file" # .$(date).tar
WEBSITE="https://nextcloud.site.com"

# Do not edit below
CURRENT_DATE=$(date +%F__%H_%M_%S)
LOG_FILE="/tmp/backup_${CURRENT_DATE}.log"
my_true=true
my_false=false

# shellcheck disable=2069
exec 2>&1 &> >(tee "${LOG_FILE}")
set -x 

notify_user () 
{
    if [[ "$1" = "${my_true}" ]]; then
        echo "OK : $2"
        # Keep going, this is OK ! 
    else
        echo "KO : $2"
        # TODO warn user by email ?
        exit 1
    fi
}

check_status () 
{
    # Is site up ? If not, don't make backup, because something is probably broken.
    status_code=$(curl -I ${WEBSITE} -s | grep HTTP | cut -d" " -f 2)

    # shellcheck disable=2055
    # I want an OR condition because nextcloud will answer with a 200 OR 302 HTTP CODE (redirect to login if anonymous)
    if [[ "${status_code}" -ne 200 || "${status_code}" -ne 302 ]]; then
        notify_user my_false "Site appears to be unavailable. I won't make backup that would be unusuable."
    fi

    if [[ ! -d $BACKUP_STOCK ]]; then
        notify_user my_false "($BACKUP_LOCATION) doesn't exists !"
    fi

    if [[ ! -d $BACKUP_DIR ]]; then
        notify_user false "Their is no directory to backup,  '($BACKUP_DIR)' doesn't exist !"
    fi

    remain_disk=$(ssh ${SSH_DETAILS} df -h ${BACKUP_LOCATION} | tail -1 | xargs | cut -d" " -f 5 | sed "s/.$//")

    if [[ "${remain_disk}" -ge 90 ]]; then
        notify_user my_false "Their is no more space left on backup device."
    fi
}

remove_old_backup () 
{
    # TODO
    echo ""
}

echo "${LOG_FILE} : Going to start.."
remote_folders=$(ssh $SSH_DETAILS find $BACKUP_DIR -maxdepth 1 -type d)

n=0
array=()
for i in $remote_folders
do 
    if [[ "$i" = "$BACKUP_DIR"  ]]; then
        continue
    fi
    array[$n]=$i
    ((n++))
done

sorted=($(sort <<<"${array[*]}"))

for index in "${!sorted[@]}"
do
    echo "$index ${sorted[index]}"
done

# Chercher le dernier directory 
# Si le dernier directory < 15j , on continue d'incrémenter dessus
# Sinon, on en crée un ouveau avec la date du jour et c'est parti pour une complète (en pensant à reset le .incremental.status)

# penser à define + create le directory

# What about deleted files ? With this method, they might not be deleted as we only diff file.
# Make a rsync with this ? with --delete flag to make sure it delete ?
cd ${BACKUP_DIR} && tar -vczf "$HOME/${BASENAME_BACKUP}.${CURRENT_DATE}.tar.gz" --listed-incremental="$HOME/.incremental.status" .

# Check that tar is OK 
if ! tar tf "$HOME/${BASENAME_BACKUP}.${CURRENT_DATE}.tar.gz"; then
    notify_user my_false "Error while creating tar file."
fi

scp "$HOME/${BASENAME_BACKUP}.${CURRENT_DATE}.tar.gz" "${SSH_DETAILS}:${BACKUP_LOCATION}"
rm -f "$HOME/${BASENAME_BACKUP}.${CURRENT_DATE}.tar.gz"

echo "Upload OK."

# Tous les directory dont le nom date de plus de 30j , remove