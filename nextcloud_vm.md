# Nextcloud VM

## Setup

1. `sudo apt update && sudo apt install mysql-server mysql-client rsync curl ssh`

2. Create an user 'epsi-nextcloud', upload files and run setup_secret.sh.

    ```bash
    # sudo adduser epsi-nextcloud && sudo su epsi-nextcloud
    $ scp backup.sh epsi-nextcloud@192.200.0.2:~
    $ scp backup_vars.sh epsi-nextcloud@192.200.0.2:~/vars.sh
    $ vim ~/vars.sh # Fill values on backup host, as epsi-nextcloud
    $ scp setup.sh epsi-nextcloud@192.200.0.2:~
    $ ./setup.sh
    ```

3. add to the `/home/epsi-backup/.ssh/authorized_keys` the public key of  `epsi-backup` user

4. Make sure the nextcloud is well configured (nginx, write access, ...)

5. Add the user `epsi-nextcloud` to the www-data group. `sudo adduser epsi-nextcloud www-data`

6. `# chown -R www-data: /var/www/`

7. `# chmod -R 2770 /var/www/`

    This is to make sure that the group www-data will have write permissions

8. Setup Master MySQL replication

    a. edit the MySQL configuration located at `/etc/mysql/mysql.conf.d/mysqld.cnf` and adapt the configuration.

        - server-id = 1
        - log_bin = /var/log/mysql/mysql-bin.log
        - binlog_do_db = nextcloud
        - bind-address = 192.200.0.2

    b. restart mysql : `sudo service mysql restart`

    c. open a terminal MySQL as root and type the following :

        - GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%' IDENTIFIED BY 'slave';
        - FLUSH PRIVILEGES;
        - SHOW MASTER STATUS; # Note the position & file values, they'll be usefull later.
        # Now we will perform a dump of the current database state.
        - use nextcloud;
        - FLUSH TABLES WITH READ LOCK;
        - QUIT;
        - `mysqldump -u root -p nextcloud > script.sql`
        # Go back to a MySQL terminal as root
        - UNLOCK TABLES;
        # Create restauration user
        - create user "restore"@"localhost" identified by "restore";
        - grant all privileges on nextcloud.* to "restore"@"localhost";
        - grant DROP, CREATE on nextcloud.* to "restore"@"localhost";
        - flush privileges;

9. `sudo mysql_secure_installation` (optional, but recommanded)

10. Important !

    - `# sudo visudo`
    - Add to the end of the file
    ```bash
        epsi-nextcloud ALL=(ALL) NOPASSWD: /bin/chown
        epsi-nextcloud ALL=(ALL) NOPASSWD: /bin/chmod
    ```

## Backup

`$ ./backup.sh`

## Cron example

`$ crontab -e # As epsi-nextcloud`
`0 */12 * * * /home/epsi-nextcloud/backup.sh >/dev/null 2>&1`