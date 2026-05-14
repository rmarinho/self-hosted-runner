#!/bin/bash

REPO=$REPO
NAME="${NAME:-runner}-$(hostname | tail -c 9)"

# Fix Docker socket permissions if mounted
if [ -S /var/run/docker.sock ]; then
  sudo chmod 666 /var/run/docker.sock
fi

cd /home/docker/actions-runner || exit

# Support both PAT-based (auto-renewing) and one-time REG_TOKEN
if [ -n "$GITHUB_PAT" ]; then
  echo "Obtaining registration token via PAT..."
  REG_TOKEN=$(curl -sX POST \
    -H "Authorization: token ${GITHUB_PAT}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${REPO}/actions/runners/registration-token" | jq -r .token)
  if [ "$REG_TOKEN" = "null" ] || [ -z "$REG_TOKEN" ]; then
    echo "ERROR: Failed to obtain registration token. Check GITHUB_PAT permissions (needs 'repo' scope)."
    exit 1
  fi
elif [ -z "$REG_TOKEN" ]; then
  echo "ERROR: Set either GITHUB_PAT or REG_TOKEN in .env"
  exit 1
fi

./config.sh --url "https://github.com/${REPO}" --token "${REG_TOKEN}" --name "${NAME}" --unattended --replace

cleanup() {
  echo "Removing runner..."
  if [ -n "$GITHUB_PAT" ]; then
    REMOVE_TOKEN=$(curl -sX POST \
      -H "Authorization: token ${GITHUB_PAT}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${REPO}/actions/runners/remove-token" | jq -r .token)
    ./config.sh remove --unattended --token "${REMOVE_TOKEN}"
  else
    ./config.sh remove --unattended --token "${REG_TOKEN}"
  fi
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!