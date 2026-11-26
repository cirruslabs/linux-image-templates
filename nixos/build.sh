#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 VM_NAME" >&2
  exit 2
fi

vm_name=$1
iso_url=https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-aarch64-linux.iso

if [[ ! $vm_name =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  echo "Choose a local Tart VM name using letters, numbers, dots, underscores, or hyphens." >&2
  exit 2
fi

if [[ $(uname -s) != Darwin || $(uname -m) != arm64 ]]; then
  echo "NixOS requires an Apple Silicon Mac with native ARM64 tools." >&2
  exit 1
fi

for tool in curl packer shasum tart; do
  if ! command -v "$tool" >/dev/null; then
    echo "Missing required tool: $tool" >&2
    exit 1
  fi
done

if tart get "$vm_name" >/dev/null 2>&1; then
  echo "Tart VM '$vm_name' already exists. Choose a different name." >&2
  exit 1
fi

template_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/nixos.XXXXXX")
build_succeeded=false
cleanup() {
  rm -rf -- "$build_dir"
  if [[ $build_succeeded != true ]]; then
    tart stop "$vm_name" >/dev/null 2>&1 || true
    tart delete "$vm_name" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

iso_path="$build_dir/nixos.iso"
checksum_path="$build_dir/nixos.iso.sha256"

curl --fail --location --silent --show-error --retry 3 \
  --output "$iso_path" "$iso_url"
curl --fail --location --silent --show-error --retry 3 \
  --output "$checksum_path" "$iso_url.sha256"

expected_checksum=$(awk 'NR == 1 { print $1 }' "$checksum_path")
if [[ ! $expected_checksum =~ ^[0-9a-f]{64}$ ]]; then
  echo "NixOS returned an invalid SHA-256 checksum." >&2
  exit 1
fi
printf '%s  %s\n' "$expected_checksum" "$iso_path" | shasum -a 256 -c

packer init "$template_dir"
packer build \
  -var "iso_path=$iso_path" \
  -var "vm_name=$vm_name" \
  "$template_dir"

build_succeeded=true
echo "Built '$vm_name' from NixOS 26.05. Fresh clones log in as admin with password admin."
