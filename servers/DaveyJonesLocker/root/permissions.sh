#!/bin/bash

# sudo crontab -u root -e
# 0 * * * * /root/permissions.sh

find /home/public/Videos -type f -exec chmod 664 {} +
find /home/public/Videos -type d -exec chmod 775 {} +
chown ftp:ftp /home/public/Videos
chown sonarr:media -R /home/public/Videos/TV/Sonarr
chown plex:media -R /home/public/Videos/TV/Plex
chown radarr:media -R /home/public/Videos/Movies/Radarr
chown plex:media -R /home/public/Videos/Movies/Plex
chown plex:media -R /home/public/Videos/Other/Plays
chown plex:media -R '/home/public/Videos/Other/Music Videos'
chown plex:media -R '/home/public/Videos/Other/Uncategorized'
find '/home/public/Videos/TV/To Import' -type f -exec chmod 666 {} +
find '/home/public/Videos/TV/To Import' -type d -exec chmod 777 {} +
find '/home/public/Videos/Movies/To Import' -type f -exec chmod 666 {} +
find '/home/public/Videos/Movies/To Import' -type d -exec chmod 777 {} +
find '/home/public/Videos/Other/To Import' -type f -exec chmod 666 {} +
find '/home/public/Videos/Other/To Import' -type d -exec chmod 777 {} +
chown ftp:ftp -R '/home/public/Videos/TV/To Import'
chown ftp:ftp -R '/home/public/Videos/Movies/To Import'
chown ftp:ftp -R '/home/public/Videos/Other/To Import'

find /home/public/Downloads -type f -exec chmod 664 {} +
find /home/public/Downloads -type d -exec chmod 775 {} +
chown transmission:media -R /home/public/Downloads

find /home/public/Games -type f -exec chmod 644 {} +
find /home/public/Games -type d -exec chmod 755 {} +
chown ftp:ftp -R /home/public/Games
find '/home/public/Games/To Import' -type f -exec chmod 666 {} +
find '/home/public/Games/To Import' -type d -exec chmod 777 {} +

find /home/public/Pictures -type f -exec chmod 644 {} +
find /home/public/Pictures -type d -exec chmod 755 {} +
chown ftp:ftp -R /home/public/Pictures
find '/home/public/Pictures/To Import' -type f -exec chmod 666 {} +
find '/home/public/Pictures/To Import' -type d -exec chmod 777 {} +

chown ftp:ftp -R /home/public/Upload
find '/home/public/Upload' -type f -exec chmod 666 {} +
find '/home/public/Upload' -type d -exec chmod 777 {} +

find /home/public/Music -type f -exec chmod 664 {} +
find /home/public/Music -type d -exec chmod 775 {} +
chown ftp:ftp /home/public/Music
chown lidarr:media -R /home/public/Music/Lidarr
chown plex:media -R /home/public/Music/Plex
chown plex:media -R /home/public/Music/Picard
chown plex:media -R /home/public/Music/Unprocessed
find '/home/public/Music/To Import' -type f -exec chmod 666 {} +
find '/home/public/Music/To Import' -type d -exec chmod 777 {} +
chown ftp:ftp -R '/home/public/Music/To Import'

