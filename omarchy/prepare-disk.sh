#!/usr/bin/env bash
set -euo pipefail

# The Debian helper boots from vda with the factory disk attached as vdb.
partition=/dev/vdb2
if [[ $(blkid -s TYPE -o value "$partition") != btrfs ||
      $(blkid -s LABEL -o value "$partition") != omarchy ]]; then
  echo "Expected the Omarchy factory root on $partition" >&2
  exit 1
fi

root=$(mktemp -d)
cleanup() {
  if mountpoint -q "$root"; then
    umount "$root"
  fi
  rmdir "$root"
}
trap cleanup EXIT
mount -o subvol=@ "$partition" "$root"

test -f "$root/var/lib/omarchy/provisioning/pending"
test -x "$root/usr/bin/omarchy-provision-user"
test -x "$root/usr/bin/sshd"

install -d "$root/usr/local/sbin" "$root/etc/systemd/system/omarchy-provision-owner.service.d"
cat > "$root/usr/local/sbin/tart-provision-owner" <<'OWNER'
#!/bin/bash
set -euo pipefail

if ! id admin >/dev/null 2>&1; then
  useradd --create-home --user-group --groups wheel --shell /bin/bash admin
fi
printf 'admin:admin\n' | chpasswd
install -m 0440 /dev/stdin /etc/sudoers.d/00-tart-admin <<'SUDO'
admin ALL=(ALL) NOPASSWD:ALL
SUDO

runuser -u admin -- env OMARCHY_SETUP_CONTEXT=provision-owner \
  /usr/bin/omarchy-provision-user --first-install

printf '[Autologin]\nUser=admin\nSession=omarchy.desktop\n' >/etc/sddm.conf.d/autologin.conf
printf 'PasswordAuthentication yes\n' >/etc/ssh/sshd_config.d/50-tart-admin.conf
ufw limit 22/tcp comment "Tart SSH"
systemctl enable --now sshd.service

rm -f /var/lib/omarchy/provisioning/pending \
  /etc/systemd/system/multi-user.target.wants/omarchy-provision-owner.service
OWNER
chmod 0755 "$root/usr/local/sbin/tart-provision-owner"

# Preserve the factory unit's conditions and ordering before desktop login.
cat > "$root/etc/systemd/system/omarchy-provision-owner.service.d/90-tart-admin.conf" <<'UNIT'
[Service]
ExecStart=
ExecStart=/usr/local/sbin/tart-provision-owner
StandardInput=null
StandardOutput=journal
StandardError=journal
TTYPath=
TTYReset=no
TTYVHangup=no
TTYVTDisallocate=no
UNIT
