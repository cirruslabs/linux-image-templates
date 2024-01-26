#!/bin/bash

# Set shell options to enable fail-fast behavior
#
# * -e: fail the script when an error occurs or command fails
# * -u: fail the script when attempting to reference unset parameters
# * -o pipefail: by default an exit status of a pipeline is that of its
#                last command, this fails the pipe early if an error in
#                any of its commands occurs
#
set -euo pipefail

arch=$(uname -m)
if [ "$arch" = "x86_64" ]; then
    RUNNER_ARCH="x64"
elif [ "$arch" = "arm64" ]; then
    RUNNER_ARCH="arm64"
else
    echo "Unknown architecture: $arch"
    exit 1
fi

DOWNLOAD_URL=$(curl -sS 'https://api.github.com/repos/actions/runner/releases/latest' | jq --raw-output --arg RUNNER_ARCH "$RUNNER_ARCH" '.assets[] | select(.name | test("actions-runner-linux-\($RUNNER_ARCH)-[0-9.]+.tar.gz")) | .browser_download_url')

rm -rf actions-runner && mkdir actions-runner && cd actions-runner

wget -O - "${DOWNLOAD_URL}" | tar xz
