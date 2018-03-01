#!/bin/bash

# make sure that SSH key are available, or script will wait for password.
# Also make sure that user has write permissions on destination folder
export SSH_DETAILS="epsi-backup@192.168.56.102"

# The *distant* folder where we want to store the backup
export BACKUP_DIR="/var/www/html/nextcloud"

# The *local* folder that we want to backup
export BACKUP_LOCATION="/home/epsi-backup/backup"

# The website URL.
# This is use to check that the website is on, before going to backup the site.
# If the website if down, there is no need to make a corrupted/unusable backup
export WEBSITE="https://nextcloud.site.com"

# Make a complete backup every X days.
# If you want to make a complete backup every time the script run, set 0.
export ONE_COMPLETE_EVERY_X_DAYS=0

# Keep the X last complete backup.
export KEEP_X_COMPLETE=5

# The **remote** SQL user, on remote host (aka backup host)
export SQL_USER=backup

# The **remote** SQL password, on remote host (aka backup host)
export SQL_PASSWORD=backup 

# The **remote** SQL database, on remote host (aka backup host)
export SQL_DB=nextcloud 
