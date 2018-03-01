#!/bin/sh

if test $# -ne 1; then 
    echo "Usage : $0 backup/nextcloud"
    echo "Backup - setup the backup host's secrets"
    echo "Nextcloud - setup the nextcloud host's secrets"
    exit 1
fi

setup_backup () 
{
    user=$(whoami)
    if test "$user" != "epsi-backup"; then
        echo "Invalid user ! Run this script as epsi-backup only."
        exit 1
    fi
    ssh-keygen -t rsa -b 4096 -C "BACKUP@BACKUP" -f ~/.ssh/id_rsa
    echo "Below is the public key you'll need to add in ~/.ssh/authorized_keys in **NEXTCLOUD** host"
    cat ~/.ssh/id_rsa.pub
    if ! test -f ~/vars.sh; then 
        echo "No variables file !"
        exit 1
    fi
    echo "Done !"    
    exit 0
}

setup_nextcloud ()
{
    user=$(whoami)
    if test "$user" != "epsi-nextcloud"; then
        echo "Invalid user ! Run this script as epsi-nextcloud only."
        exit 1
    fi
    ssh-keygen -t rsa -b 4096 -C "NEXTCLOUD@NEXTCLOUD" -f ~/.ssh/id_rsa
    echo "Below is the public key you'll need to add in ~/.ssh/authorized_keys in **BACKUP** host"
    cat ~/.ssh/id_rsa.pub
    if ! test -f ~/vars.sh; then 
        echo "No variables file !"
        exit 1
    fi
    echo "Done !"
    exit 0
}

if test "$1" = "nextcloud"; then
    echo "Setup nextcloud"
    setup_nextcloud
elif test "$1" = "backup"; then
    echo "Setup backup"
    setup_backup
else 
    echo "Invalid parameters !"
    exit 1
fi
