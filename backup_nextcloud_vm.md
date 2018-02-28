# Backup VM

## Setup

1. Create an user 'epsi-backup' and add a ssh key *without* passphrase.

2. add to the `/home/epsi-backup/.ssh/authorized_keys` the public key of  `epsi-nextcloud` user (from the nextcloud VM)

3. Copy restore.sh script to the $HOME of epsi-backup. `scp restore.sh epsi-backup@192.200.0.3:~`

4. `sudo apt update && sudo apt install mysql-server mysql-client rsync`

5. Set up SLAVE MySQL.

    a. You first need to setup the MASTER MySQL on nextcloud instance.

    b. get the dump of the master database.

    c. create a database 'nextcloud'

    d. import the dump of the master database. `mysql -u root -p nextcloud < script.sql`

    e. edit the MySQL configuration located at `/etc/mysql/mariadb.conf.d/50-server.cnf` and adapt the configuration.

        - server-id = 2
        - log_bin = /var/log/mysql/mysql-bin.log
        - binlog_do_db = nextcloud

    f. restart mysql : `sudo service mysql restart`

    g. open a terminal MySQL as root and type the following : 

        - CHANGE MASTER TO MASTER_HOST='192.200.0.2',MASTER_USER='slave',MASTER_PASSWORD='slave',MASTER_LOG_FILE='mysql-bin.000005',MASTER_LOG_POS=327;
            - Adapt the MASTER_LOG_FILE and MASTER_LOG_POS with the values you got while setting up the master database
        - START SLAVE;
        - SHOW SLAVE STATUS\G; // to check that it is ok

6. Fill the required data in `restore.sh`

```bash
SSH_DETAILS="epsi-nextcloud@192.168.56.101" # The ssh_details to access to the nextcloud VM
BACKUP_LOCATION="/home/epsi-backup/backup" # The location of your backup, on the Backup VM. /!\ No trailing '/' /!\
RESTAURATION_LOCATION="/var/www/html/nextcloud" # Where you want to restore the data, on the nextcloud VM. /!\ No trailing '/' /!\
```

## Restauration

- run restore.sh script and follow instructions.