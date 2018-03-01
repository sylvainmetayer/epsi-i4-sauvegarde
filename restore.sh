#!/bin/bash
# shellcheck disable=2029
# shellcheck disable=2069

if ! test -f ~/vars.sh; then
    echo "ERROR, secrets missing !"
    exit 1
fi

chmod +x ~/vars.sh
source ~/vars.sh

# Do not edit below
CURRENT_DATE=$(date +%s)
LOG_FILE="/tmp/restore_${CURRENT_DATE}.log"

clear
exec 2>&1 &> >(tee "${LOG_FILE}")
echo "$LOG_FILE"

restore_db () 
{
    echo "I will now restore database."
    sql_file=$1.sql
    sql_file=$(basename "$sql_file")
    sql_location=$BACKUP_LOCATION/$sql_file
    echo "$sql_location"
    echo "$sql_file"
    echo "Drop/Create database"
    ssh "$SSH_DETAILS" "mysql -u $SQL_USER -p${SQL_PASSWORD} $SQL_DB <<< 'DROP DATABASE $SQL_DB;'"
    ssh "$SSH_DETAILS" "mysql -u $SQL_USER -p${SQL_PASSWORD} <<< 'CREATE DATABASE $SQL_DB;'"
    echo "Upload $sql_location..."
    scp "$sql_location" "$SSH_DETAILS:~"
    echo "Restauration of $sql_file into $SQL_DB ..."
    ssh "$SSH_DETAILS" "mysql -u $SQL_USER -p${SQL_PASSWORD} $SQL_DB < ~/$sql_file"
    echo "Delete $sql_file"
    ssh "$SSH_DETAILS" "rm $sql_file"
    echo "Database restaured !"
}

while :
do
    echo "Which one to restore ? (ctrl-c to quit)"
    iterator=0
    for file in ${BACKUP_LOCATION}/*; do
        if [[ $file =~ ^.*\.sql$ ]]; then
            continue
        fi
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
    if [[ $file =~ ^.*\.sql$ ]]; then
        continue
    fi
    iterator=$((iterator + 1))
    if [[ $user_choice -eq $iterator ]]; then 
        restauration_file=$file
    fi
done

ssh "$SSH_DETAILS" sudo chmod -R 2770 "$RESTAURATION_LOCATION"
ssh "$SSH_DETAILS" rm -rf "$RESTAURATION_LOCATION && mkdir -p $RESTAURATION_LOCATION"
if test -f "$restauration_file"; then
    filename=$(basename "$restauration_file")
    echo "I will restore $restauration_file"
    scp "$restauration_file" "${SSH_DETAILS}:${RESTAURATION_LOCATION}/"
    ssh "$SSH_DETAILS" "tar xf ${RESTAURATION_LOCATION}/$filename -C ${RESTAURATION_LOCATION} && rm -f ${RESTAURATION_LOCATION}/$filename"
    echo "Files restaured !"
    ssh "$SSH_DETAILS" sudo chown -R www-data "$RESTAURATION_LOCATION"
    ssh "$SSH_DETAILS" sudo chmod -R 2770 "$RESTAURATION_LOCATION"
    restore_db "${restauration_file%%.*}"
else 
    echo "I will restore last incremental backup : $file"
    scp -r "${restauration_file}"/* "${SSH_DETAILS}:${RESTAURATION_LOCATION}*"
    ssh "$SSH_DETAILS" sudo chown -R www-data "$RESTAURATION_LOCATION"
    ssh "$SSH_DETAILS" sudo chmod -R 2770 "$RESTAURATION_LOCATION"
    mysqldump -u "$SQL_LOCAL_USER" -p"$SQL_LOCAL_PASSWORD" "$SQL_LOCAL_DB" --databases --single-transaction > "$BACKUP_LOCATION/restore.sql"
    restore_db "$BACKUP_LOCATION/restore"
    rm "$BACKUP_LOCATION/restore.sql"
fi

echo "Restauration successful !"