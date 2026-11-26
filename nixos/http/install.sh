#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 HTTP_BASE_URL" >&2
  exit 2
fi

http_base_url=$1
disk=/dev/vda

parted --script "$disk" -- mklabel gpt
parted --script "$disk" -- mkpart ESP fat32 1MiB 512MiB
parted --script "$disk" -- set 1 esp on
parted --script "$disk" -- mkpart root ext4 512MiB 100%
udevadm settle

mkfs.fat -F 32 -n boot "${disk}1"
mkfs.ext4 -F -L nixos "${disk}2"
udevadm settle

mount -t ext4 "${disk}2" /mnt
mkdir -p /mnt/boot /mnt/etc/nixos
mount -t vfat "${disk}1" /mnt/boot
curl --fail --location --silent --show-error \
  --output /mnt/etc/nixos/configuration.nix \
  "$http_base_url/configuration.nix"

nixos-install --no-root-passwd
reboot
