#!/bin/bash

# I did it manually, but should be able to automate this.
# Only run it once as root

apt update && apt upgrade && apt install ssh

adduser epsi-backup 
adduser epsi-backup www-data
su epsi-backup 
cd || exit 1

echo "press enter, don't rename key, don't set passphrase."
ssh-keygen -t rsa -b 4096 -C "Server Nextcloud - epsi-backup"
cat ~/.ssh/id_rsa.pub
echo "Copy the public key above in Backup server, for the epsi-backup user."