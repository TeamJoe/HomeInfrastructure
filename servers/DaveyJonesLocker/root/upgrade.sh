#!/bin/bash
# /root/upgrade.sh

dockerClean() {
  local containerIds="$(docker ps --all --filter "status=exited" --quiet --no-trunc)"
  docker rm --volumes ${containerIds}
  local imageIds="$(docker images --all --filter "dangling=true" --quiet --no-trunc)"
  docker rmi ${imageIds}
}

upgrade() {
  docker pull ubuntu:latest
  ombi upgrade
  radarr upgrade
  sonarr upgrade
  lidarr upgrade
  bazarr upgrade
  jackett upgrade
  flaresolverr upgrade
  plexmeta upgrade
  plex upgrade
  transmission upgrade
  transmission restart
}

dockerClean
upgrade
dockerClean
