#!/bin/bash

REPO=$REPO
REG_TOKEN=$REG_TOKEN
NAME=$NAME

# Fix Docker socket permissions if mounted
if [ -S /var/run/docker.sock ]; then
  DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
  if ! getent group "$DOCKER_SOCK_GID" > /dev/null 2>&1; then
    sudo groupadd -g "$DOCKER_SOCK_GID" dockerhost
  fi
  DOCKER_GROUP=$(getent group "$DOCKER_SOCK_GID" | cut -d: -f1)
  sudo usermod -aG "$DOCKER_GROUP" docker
fi

cd /home/docker/actions-runner || exit
./config.sh --url https://github.com/${REPO} --token ${REG_TOKEN} --name ${NAME}

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!