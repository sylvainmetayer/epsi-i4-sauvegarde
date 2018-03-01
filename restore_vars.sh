#!/bin/bash

# make sure that SSH key are available, or script will wait for password.
export SSH_DETAILS="epsi-nextcloud@192.168.56.101"

# The **local** folder where are stored our backup. No trailing '/' ! 
export BACKUP_LOCATION="/home/epsi-backup/backup"

# The *distant* folder where we want to restore the data. No trailing '/' !
export RESTAURATION_LOCATION="/var/www/html/nextcloud"

# The *remote* SQL database, to restore the database
export SQL_DB="nextcloud" 

# The *remote* SQL user, to restore the database
export SQL_USER="restore"

# The *remote* SQL password, to restore the database 
export SQL_PASSWORD="restore"

# The *local* SQL database, if we need to make a dump of the slave
export SQL_LOCAL_DB="nextcloud"

# The *local* SQL user, if we need to make a dump of the slave
export SQL_LOCAL_USER="backup" # Local, the slave

# The *local* SQL password, if we need to make a dump of the slave
export SQL_LOCAL_PASSWORD="backup" # Local, the slave
