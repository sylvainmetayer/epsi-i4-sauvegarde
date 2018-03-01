# Nextcloud VM

## Setup

1. Create an user 'epsi-nextcloud' and add to this user a ssh key *without* passphrase.

    ```bash
    sudo adduser epsi-nextcloud && sudo su epsi-nextcloud
    ssh-keygen -t rsa -b 8192 -C "NEXTCLOUD@NEXTCLOUD"
    ```

2. add to the `/home/epsi-backup/.ssh/authorized_keys` the public key of  `epsi-backup` user (from the nextcloud VM)

3. Copy backup.sh script to the $HOME of epsi-nextcloud. `scp backup.sh epsi-nextcloud@192.200.0.2:~`

4. `sudo apt update && sudo apt install mysql-server mysql-client rsync curl`

5. Make sure the nextcloud is well configured (nginx, write access, ...)

6. Add the user `epsi-nextcloud` to the www-data group. `sudo adduser epsi-nextcloud www-data`

7. `# chown -R www-data: /var/www/`

8. `# chmod -R 2770 /var/www/`

    This is to make sure that the group www-data will have write permissions

9. Setup Master MySQL replication

    a. edit the MySQL configuration located at `/etc/mysql/mariadb.conf.d/50-server.cnf` and adapt the configuration.

        - server-id = 1
        - log_bin = /var/log/mysql/mysql-bin.log
        - binlog_do_db = nextcloud
        - bind-address = 192.200.0.2

    b. restart mysql : `sudo service mysql restart

    c. open a terminal MySQL as root and type the following :

        - GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%' IDENTIFIED BY 'slave';
        - FLUSH PRIVILEGES;
        - SHOW MASTER STATUS; # Note the position & file values, they'll be usefull later.
        # Now we will perform a dump of the current database state.
        - use nextcloud;
        - FLUSH TABLES WITH READ LOCK;
        - QUIT;
        - `mysql -u root -p nextcloud > script.sql`
        # Go back to a MySQL terminal as root
        - UNLOCK TABLES;
        # Create restauration user
        - create user "restore"@"localhost" identified by "restore";
        - grant all privileges on nextcloud.* to "restore"@"localhost";
        - grant DROP, CREATE on nextcloud.* to "restore"@"localhost";
        - flush privileges;

10. Fill the required data in `backup.sh`

    ```bash
    SSH_DETAILS="epsi-backup@192.168.56.102" # The ssh_details to access to the backup VM
    BACKUP_DIR="/var/www/nextcloud" # The directory you want to backup, on the nextcloud host.
    BACKUP_LOCATION="/home/epsi-backup/backup" # Where you want to store the backup, on the backup VM.
    WEBSITE="https://192.200.0.2" # The URL of the nextcloud site.
    ONE_COMPLETE_EVERY_X_DAYS=10 # Make a complete backup every X days, e.g every 10 days.
    KEEP_X_COMPLETE=3 # Keep the X most recent complete backup, e.g keep the 3 most recent
    ```

11. `sudo mysql_secure_installation` (optional, but recommanded)

With this configuration, it means we have a 30 days complete backup image (10*3) + an incremental backup.