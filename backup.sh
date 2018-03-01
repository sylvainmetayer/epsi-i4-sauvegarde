#!/bin/bash
# shellcheck disable=2029

# make sure that SSH key are available, or script will wait for password.
# Also make sure that user has write permissions on destination folder
SSH_DETAILS="epsi-backup@192.168.56.102"
BACKUP_DIR="/var/www/nextcloud"
BACKUP_LOCATION="/home/epsi-backup/backup"
WEBSITE="https://nextcloud.site.com"
ONE_COMPLETE_EVERY_X_DAYS=0
KEEP_X_COMPLETE=5
SQL_USER=backup # On remote host
SQL_PASSWORD=backup # On remote host
SQL_DB=nextcloud # On remote host

# Do not edit below
CURRENT_DATE=$(date +%s)
LOG_FILE="/tmp/backup_${CURRENT_DATE}.log"
my_true=true
my_false=false
timestamp_before_complete_bck=$(( ONE_COMPLETE_EVERY_X_DAYS * 24 * 60 * 60 ))
incremental_folder="incremental"

# shellcheck disable=2069
exec 2>&1 &> >(tee "${LOG_FILE}")
# set -x 

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

backup_mysql () 
{
    ssh $SSH_DETAILS mysqldump -u $SQL_USER -p$SQL_PASSWORD $SQL_DB --databases --single-transaction > "$HOME/$CURRENT_DATE.sql"
    scp "$HOME/$CURRENT_DATE.sql" $SSH_DETAILS:$BACKUP_LOCATION
}

check_status () 
{
    # Is site up ? If not, don't make backup, because something is probably broken.
    status_code=$(curl -I ${WEBSITE} -s | grep HTTP | cut -d" " -f 2)

    # shellcheck disable=2055
    # I want an OR condition because nextcloud will answer with a 200 OR 302 HTTP CODE (redirect to login if anonymous)
    if [[ "${status_code}" == "200" ]]; then
        echo "Status code 200 ok."
    elif [[ "${status_code}" == "302" ]]; then
        echo "Status code 302 ok."
    else 
        notify_user my_false "Site appears to be unavailable. I won't make backup that would be unusuable."
    fi

    # TODO Check location ?

    if [[ ! -d $BACKUP_DIR ]]; then
        notify_user false "Their is no directory to backup,  '$BACKUP_DIR)' doesn't exist !"
    fi

    remain_disk=$(ssh ${SSH_DETAILS} df -h ${BACKUP_LOCATION} | tail -1 | xargs | cut -d" " -f 5 | sed "s/.$//")

    if [[ "${remain_disk}" -ge 90 ]]; then
        notify_user my_false "Their is no more space left on backup device."
    fi
}

# Main
echo "${LOG_FILE} : Going to start.."

echo "A few verifications before starting.."
check_status

complete_backup_str=$(ssh $SSH_DETAILS "ls ${BACKUP_LOCATION}/*.tar.bz2 2>/dev/null | xargs | tr ' ' '\n' | sort -r")

n=0
complete_backup=()
for i in $complete_backup_str
do 
    complete_backup[$n]=$i
    ((n++))
done

echo "TODO Set maintenance ON"
ssh $SSH_DETAILS mkdir -p "$BACKUP_LOCATION/$incremental_folder"
rsync -arv --delete $BACKUP_DIR/ $SSH_DETAILS:$BACKUP_LOCATION/$incremental_folder >/dev/null

nb_of_complete_bck=${#complete_backup[@]}

if [[ $nb_of_complete_bck -le 0 ]]; then
    echo "Their is no complete backup. Let's make one."
    ssh $SSH_DETAILS "cd $BACKUP_LOCATION/$incremental_folder && tar -cvjf $BACKUP_LOCATION/${CURRENT_DATE}.tar.bz2 . >/dev/null"
    # Check that tar is OK 
    if ! ssh $SSH_DETAILS tar tf "$BACKUP_LOCATION/${CURRENT_DATE}.tar.bz2" >/dev/null ; then
        notify_user my_false "Error while creating tar file."
    fi
    backup_mysql
else
    most_recent=$(basename "${complete_backup[0]}")
    most_recent=${most_recent%%.*}
    delta=$(( CURRENT_DATE - most_recent ))
    if [[ $delta -gt $timestamp_before_complete_bck ]]; then 
        echo "Time to make a new complete backup !"
        ssh $SSH_DETAILS "cd $BACKUP_LOCATION/$incremental_folder && tar -cvjf $BACKUP_LOCATION/${CURRENT_DATE}.tar.bz2 . >/dev/null"
        backup_mysql
    else
        echo "Their is no need to make a complete backup right now."
    fi
fi

echo "Backup complete. Check old one to delete. We'll keep the ${KEEP_X_COMPLETE} most recent complete backup."
echo "TODO Set maintenance OFF"

complete_backup_str=$(ssh $SSH_DETAILS "ls ${BACKUP_LOCATION}/*.tar.bz2 2>/dev/null | xargs | tr ' ' '\n' | sort -r")
n=0
complete_backup=()
iter=0
for i in $complete_backup_str
do 
    iter=$(( iter + 1))
    if [[ $iter -le $KEEP_X_COMPLETE ]]; then
        continue
    fi
    echo "Going to delete $SSH_DETAILS:$i"
    ssh $SSH_DETAILS rm "$i"
    echo "Going to delete ${i%%.*}.sql"
    ssh $SSH_DETAILS rm "${i%%.*}.sql"
done

echo "Finish backup !"
