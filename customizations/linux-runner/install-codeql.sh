#!/bin/bash

# Is need for Copilot Coding Agent

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
    RUNNER_ARCH="linux64"
else
    echo "Unknown architecture: $arch"
    exit 1
fi

export AGENT_TOOLSDIRECTORY=$HOME/hostedtoolcache
export RUNNER_TOOL_CACHE=$HOME/hostedtoolcache

# Inspired by https://github.com/actions/runner-images/blob/main/images/ubuntu/scripts/build/install-codeql-bundle.sh

# Retrieve the latest major version of the CodeQL Action to use in the base URL for downloading the bundle.
releases=$(curl -s "https://api.github.com/repos/github/codeql-action/releases")

# Get the release tags starting with v[0-9] and sort them in descending order, then parse the first one to get the major version.
codeql_action_latest_major_version=$(echo "$releases" |
    jq -r '.[].tag_name' |
    grep -E '^v[0-9]' |
    sort -nr |
    head -n 1 |
    sed -E 's/^v([0-9]+).*/\1/')
if [ -z "$codeql_action_latest_major_version" ]; then
  echo "Error: Unable to find the latest major version of the CodeQL Action."
  exit 1
fi

# Retrieve the CLI version of the latest CodeQL bundle.
base_url="$(curl -fsSL https://raw.githubusercontent.com/github/codeql-action/v"$codeql_action_latest_major_version"/src/defaults.json)"
bundle_version="$(echo "$base_url" | jq -r '.cliVersion')"
bundle_tag_name="codeql-bundle-v$bundle_version"

echo "Downloading CodeQL bundle $bundle_version..."
# Note that this is the all-platforms CodeQL bundle, to support scenarios where customers run
# different operating systems within containers.
codeql_toolcache_path="$AGENT_TOOLSDIRECTORY/CodeQL/$bundle_version/$RUNNER_ARCH"
mkdir -p "$codeql_toolcache_path"

curl -fsSL "https://github.com/github/codeql-action/releases/download/$bundle_tag_name/codeql-bundle-$RUNNER_ARCH.tar.gz" | tar -xz -C "$codeql_toolcache_path"

# Touch a file to indicate to the CodeQL Action that this bundle shipped with the toolcache. This is
# to support overriding the CodeQL version specified in defaults.json on GitHub Enterprise.
touch "$codeql_toolcache_path/pinned-version"

# Touch a file to indicate to the toolcache that setting up CodeQL is complete.
touch "$codeql_toolcache_path.complete"

echo "CodeQL bundle $bundle_version installed successfully at $codeql_toolcache_path"


