# Pré-requis

- `apt update && apt upgrade && apt install ssh`

Sur l'instance Nextcloud, créer un utilisateur "epsi-backup" (password : epsi-backup) et l'ajouter au groupe www-data.
Générer une clé SSH (`ssh-keygen -t rsa -b 4096 -C "Server Nextcloud - epsi-backup"`) 

#  Files Backup
Sur le serveur de backup, créer un utilisateur epsi-backup et ajouter dans le fichier `.ssh/authorized_keys` la clé publique générée précedemment.

Sur le serveur, voici le script de sauvegarde (il faudra mettre ce script dans un cron qui tourne tout les jours par exemple)

```bash
#!/bin/sh

rsync -e ssh -azp /var/www/html/nextcloud/data/ epsi-backup@192.168.56.104:~/nextcloud-files/$(date +%F--%H:%I:%S)
```

Sur le serveur de sauvegarde, créer le script suivant qui va vérifier que le dossier ne contient pas plus de X dossiers, et supprimer les plus anciens au besoin.

-- TODO 

# Files restauration

Sur le serveur de sauvegarde, voici le script de restauration. Il est nécessaire d'avoir des clés SSH pour pouvoir se connecter du script de sauvegarde vers le serveur nextcloud

```
#!/bin/sh
files=/tmp/$$

for file in /home/epsi-backup/nextcloud-files/*
do
    if [ -d $file ]; then
        echo "${file##*/}" >> $files
    fi
done

sort -r $files -o $files
directoryToRestore=$(head -n1 $files)
# TODO Restore the selected folder that is the last one.
```
