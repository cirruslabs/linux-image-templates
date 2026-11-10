#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [vm-name]" >&2
  exit 2
fi

vm_name=${1-omarchy}
if [[ ! $vm_name =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  echo "Choose a local Tart VM name using letters, numbers, dots, underscores, or hyphens." >&2
  exit 2
fi

if [[ $(uname -s) != Darwin || $(uname -m) != arm64 ]]; then
  echo "Omarchy requires an Apple Silicon Mac with native ARM64 tools." >&2
  exit 1
fi

for tool in tart packer jq zstd; do
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
packer init "$template_dir"

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/omarchy.XXXXXX")
helper_vm=
staging_vm=
cleanup() {
  if [[ -n $helper_vm ]]; then
    tart stop "$helper_vm" >/dev/null 2>&1 || true
    tart delete "$helper_vm" >/dev/null 2>&1 || true
  fi
  if [[ -n $staging_vm ]]; then
    tart delete "$staging_vm" >/dev/null 2>&1 || true
  fi
  rm -rf -- "$build_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Use one release record for both the disk assets and the published tag.
curl --fail --location --silent --show-error --retry 3 \
  --header 'Accept: application/vnd.github+json' \
  --output "$build_dir/release.json" \
  https://api.github.com/repos/omacom/try-omarchy/releases/latest

release_tag=$(jq -r '.tag_name | strings' "$build_dir/release.json")
if [[ ! $release_tag =~ ^[a-zA-Z0-9_][a-zA-Z0-9._-]{0,127}$ || $release_tag == latest ]]; then
  echo "Try Omarchy returned an invalid version tag for the registry." >&2
  exit 1
fi

release_url="https://github.com/omacom/try-omarchy/releases/download/$release_tag"
image=omarchy-aarch64-edge.img.zst
echo "Building Try Omarchy $release_tag"
jq -er --arg image "$image" '
  [.assets[] | select(.name == $image)] as $whole_disk
  | if $whole_disk != [] then $whole_disk
    else [
      .assets[]
      | select(.name | startswith($image + "."))
      | select(.name | ltrimstr($image + ".") | test("^[0-9]{3}$"))
    ] | sort_by(.name)
    end
  | if length == 0 then error("No ARM64 factory disk found")
    elif $whole_disk == [] and
      ([.[].name | ltrimstr($image + ".") | tonumber] != [range(1; length + 1)])
    then error("ARM64 factory disk parts must be numbered from 001 without gaps")
    elif any(.[]; (.digest // "") | test("^sha256:[0-9a-f]{64}$") | not)
    then error("Missing SHA-256 digest for an ARM64 factory disk asset")
    else .[] | [.name, (.digest | ltrimstr("sha256:"))] | @tsv
    end
' "$build_dir/release.json" > "$build_dir/assets.tsv"

(
  cd "$build_dir"
  disk_parts=()
  while IFS=$'\t' read -r asset checksum; do
    echo "Downloading $asset"
    curl --fail --location --silent --show-error --retry 3 \
      --output "$asset" "$release_url/$asset"
    printf '%s  %s\n' "$checksum" "$asset" | shasum -a 256 -c
    disk_parts+=("$asset")
  done < assets.tsv

  cat "${disk_parts[@]}" | zstd --decompress --sparse -o disk.img
)

helper_vm="omarchy-prepare-$(uuidgen)"
TART_NO_AUTO_PRUNE=1 tart clone ghcr.io/cirruslabs/debian:trixie "$helper_vm"
tart run --no-graphics --no-clipboard --disk "$build_dir/disk.img" "$helper_vm" &
helper_pid=$!
tart ip "$helper_vm" --resolver agent --wait 60 >/dev/null
tart exec -i "$helper_vm" sudo -n bash -se < "$template_dir/prepare-disk.sh"
tart stop "$helper_vm"
wait "$helper_pid"
tart delete "$helper_vm"
helper_vm=

# Stage the disk before Packer configures it. Tart's rename rejects an existing
# destination even if another build created it after our initial check.
staging_vm="omarchy-build-$(uuidgen)"
tart create --linux --disk-size 1 "$staging_vm"
tart set "$staging_vm" --disk "$build_dir/disk.img" --display-refit
packer build -var "vm_name=$staging_vm" "$template_dir"
if [[ -n ${GITHUB_OUTPUT:-} ]]; then
  printf 'release_tag=%s\n' "$release_tag" >> "$GITHUB_OUTPUT"
fi
tart rename "$staging_vm" "$vm_name"
staging_vm=
echo "Built '$vm_name' from Try Omarchy $release_tag. Fresh clones log in as admin with password admin."
