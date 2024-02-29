#!/bin/bash

chown bazarr:media -R /home/bazarr
chmod 700 -R /home/bazarr
chmod 000 /home/bazarr/cred*

chown compression:compression -R /home/compression
chmod 700 -R /home/compression
chmod 000 /home/compression/cred*

#chown docker:docker -R /home/docker
#chmod 700 -R /home/docker
chmod 000 /home/docker/cred*

chown jackett:media -R /home/jackett
chmod 700 -R /home/jackett
chmod 000 /home/jackett/cred*

chown lidarr:media -R /home/lidarr
chmod 700 -R /home/lidarr
chmod 000 /home/lidarr/cred*

chown nzbget:media -R /home/nzbget
chmod 775 -R /home/nzbget
chmod 000 /home/nzbget/cred*

chown ombi:media -R /home/ombi
chmod 700 -R /home/ombi
chmod 000 /home/ombi/cred*

chown plex:media -R /home/plex
chmod 775 -R /home/plex
chmod 000 /home/plex/cred*

chown plexmeta:media -R /home/plexmeta
chmod 775 -R /home/plexmeta
chmod 000 /home/plexmeta/cred*

chown radarr:media -R /home/radarr
chmod 700 -R /home/radarr
chmod 000 /home/radarr/cred*

chown root:root -R /home/samba
chmod 700 -R /home/samba
chmod 000 /home/samba/cred*

chown sonarr:media -R /home/sonarr
chmod 700 -R /home/sonarr
chmod 000 /home/sonarr/cred*

chown flaresolverr:media -R /home/flaresolverr
chmod 775 -R /home/flaresolverr
chmod 000 /home/flaresolverr/cred*

chown transmission:media -R /home/transmission
chmod 775 -R /home/transmission
chmod 000 /home/transmission/cred*

chown vpn:vpn -R /home/vpn
chmod 755 -R /home/vpn
chmod 000 /home/vpn/cred*

chown ftp:ftp -R /home/vsftpd
chmod 700 -R /home/vsftpd
chmod 000 /home/vsftpd/cred*

chown ftp:ftp /home/public
chmod 555 /home/public

chown ftp:ftp /home2/public
chmod 555 /home2/public

find /home/public/Videos -type f -exec chmod 664 {} +
find /home/public/Videos -type d -exec chmod 775 {} +
chown ftp:ftp /home/public/Videos
chown sonarr:media -R /home/public/Videos/TV/Anime
chown sonarr:media -R /home/public/Videos/TV/Hentai
chown sonarr:media -R /home/public/Videos/TV/Sonarr
chown sonarr:media -R /home/public/Videos/TV/Sonarr-Hentai
chown plex:media -R /home/public/Videos/TV/Plex
chown radarr:media -R /home/public/Videos/Movies/Anime
chown radarr:media -R /home/public/Videos/Movies/Hentai
chown radarr:media -R /home/public/Videos/Movies/Radarr
chown radarr:media -R /home/public/Videos/Movies/Radarr-Hentai
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

