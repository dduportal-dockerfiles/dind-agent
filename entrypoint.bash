#!/bin/bash
#
# This entrypoint is dedicated to start Docker Engine (in Docker)
# For CloudBees Jenkins Enterprise 1.x Agent Templates
# Configured with a "DUMMY" argument (needed to start JNLP process)
#

set -e

if [ $# -gt 0 ]
then
  # first argument is the custom docker command shell provided by plugin
  echo "== Starting Docker Engine"
  /usr/local/bin/dockerd-entrypoint.sh >/docker.log 2>&1 &

  # Wait for Docker to start by checking the TCP socket locally
  ## Wait 1 second to let all process and file handle being created
  echo "== Waiting for Docker Engine to start"
  sleep 1
  ## Try reaching the unix socket for 30s, all the 6
  curl -XGET -vsS -o /dev/null --fail \
    --retry 6 --retry-delay 5 \
    --unix-socket /var/run/docker.sock \
    http://DUMMY/_ping || (cat /docker.log && exit 1)
  ## Last check: the _ping endpoint should send "OK" on stdout
  [ "$(curl -sS -X GET --unix-socket /var/run/docker.sock http:/images/_ping)" == "OK" ]
  echo "== Docker Engine started and ready"

  # Load any "tar-ed" docker image from the local FS cache
  if [ -n "${DOCKER_IMAGE_CACHE_DIR}" ] && [ -d "${DOCKER_IMAGE_CACHE_DIR}" ]
  then
    echo "== Variable 'DOCKER_IMAGE_CACHE_DIR' found and pointing to an existing Directory"
    echo "== Loading following .tar files in Docker:"
    find "${DOCKER_IMAGE_CACHE_DIR}" -type f -name "*.gz" -print \
      -exec sh -c 'gunzip --stdout "$1" | docker load' -- {} \;
  fi

  # second argument is the java command line generated by the plugin (passed as a single arg)
  shift
  echo "== Launching the following user-provided command: ${*}"
  exec /bin/sh -c "$@"
fi