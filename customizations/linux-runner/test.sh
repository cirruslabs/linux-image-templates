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

# Ensure that ANDROID_HOME environment variable is set
test ! -z "${ANDROID_HOME}"

installed_android_packages="$("$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --list_installed)"

installed_android_platforms_below_35_count="$(
  awk -F'|' '/^[[:space:]]*platforms;android-[0-9]+[[:space:]]*\|/ {
      split($1, path, ";")
      split(path[2], version, "-")
      if (version[2] < 35) count++
    } END { print count + 0 }' \
    <<<"$installed_android_packages"
)"

test "$installed_android_platforms_below_35_count" -eq 0
grep -Fq "platforms;android-35" <<<"$installed_android_packages"

if [[ "$(uname -m)" == "x86_64" ]]; then
  installed_android_x86_64_system_images_below_35_count="$(
    awk -F'|' '/^[[:space:]]*system-images;android-[0-9]+;google_apis;x86_64[[:space:]]*\|/ {
        split($1, path, ";")
        split(path[2], version, "-")
        if (version[2] < 35) count++
      } END { print count + 0 }' \
      <<<"$installed_android_packages"
  )"

  test "$installed_android_x86_64_system_images_below_35_count" -eq 0
  grep -Fq "system-images;android-35;google_apis;x86_64" <<<"$installed_android_packages"
fi
