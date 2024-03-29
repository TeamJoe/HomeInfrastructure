#!/bin/bash
# /root/upgrade.sh

LOG_FILE='/root/upgrade.log'

dockerClean() {
  local containerIds="$(docker ps --all --filter "status=exited" --quiet --no-trunc)"
  docker rm --volumes ${containerIds}
  local imageIds="$(docker images --all --filter "dangling=true" --quiet --no-trunc)"
  docker rmi ${imageIds}
}

runService() {
  sudo -u ${1} --shell /bin/bash /home/${1}/${1}.sh ${2}
}

upgrade() {
  docker pull ubuntu:latest
  runService ombi upgrade
  runService radarr upgrade
  runService sonarr upgrade
  runService lidarr upgrade
  runService bazarr upgrade
  runService jackett upgrade
  runService flaresolverr upgrade
  runService plexmeta upgrade
  runService plex upgrade
  runService transmission update
  runService transmission restart
}

upgradeServices() {
  echo "[$(date -u "+%Y-%m-%dT%H:%M:%SZ")]"
  dockerClean
  upgrade
  dockerClean
}

upgradeServices >> "${LOG_FILE}" 2>&1