# Backup VM

## Setup

1. `sudo apt update && sudo apt install mysql-server mysql-client rsync curl ssh`

2. Create an user 'epsi-backup' upload files and run setup_secret.sh.

    ```bash
    # sudo adduser epsi-backup && sudo su epsi-backup
    $ scp restore.sh epsi-backup@192.200.0.3:~
    $ scp restore_vars.sh epsi-backup@192.200.0.3:~/vars.sh
    $ vim ~/vars.sh # Fill values on backup host, as epsi-backup
    $ scp setup.sh epsi-backup@192.200.0.3:~
    $ ./setup.sh
    ```

3. add to the `/home/epsi-nextcloud/.ssh/authorized_keys` the public key of  `epsi-backup` user

4. Set up SLAVE MySQL.

    a. You first need to setup the MASTER MySQL on nextcloud instance.

    b. get the dump of the master database.

    c. create a database 'nextcloud' `mysql> create database nextcloud;`

    d. import the dump of the master database. `mysql -u root -p nextcloud < script.sql`

    e. edit the MySQL configuration located at `/etc/mysql/mysql.conf.d/mysqld.cnf` and adapt the configuration.

        - server-id = 2
        - log_bin = /var/log/mysql/mysql-bin.log
        - binlog_do_db = nextcloud

    f. restart mysql : `# sudo service mysql restart`

    g. open a terminal MySQL as root and type the following :

        - CHANGE MASTER TO MASTER_HOST='192.200.0.2',MASTER_USER='slave',MASTER_PASSWORD='slave',MASTER_LOG_FILE='mysql-bin.000005',MASTER_LOG_POS=327;
            - Adapt the MASTER_LOG_FILE and MASTER_LOG_POS with the values you got while setting up the master database
        - START SLAVE;
        - SHOW SLAVE STATUS\G; // to check that it is ok

    h. Create an user for the backup of database.

        - create user 'backup'@'localhost' identified by 'backup';
        - GRANT SELECT, SHOW VIEW, LOCK TABLES ON nextcloud.* to 'backup'@'localhost' identified by 'backup';
        - GRANT REPLICATION SLAVE on *.* to 'backup'@'localhost';
        - flush privileges;

5. `sudo mysql_secure_installation` (optional, but recommanded)

## Restauration

- run restore.sh script and follow instructions.
