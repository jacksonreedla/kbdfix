#!/bin/bash
# Step 2 only: install the sleep hook. (Step 1, the live unbind/bind proof,
# already passed - no need to drop the keyboard again.)
set -euo pipefail
SP="$(cd "$(dirname "$0")" && pwd)"
[ "$(id -u)" = 0 ] || { echo "must run as root"; exit 1; }

mkdir -p /etc/systemd/system-sleep
install -m 0755 -o root -g root "$SP/i8042-resume-fix" /etc/systemd/system-sleep/i8042-resume-fix

echo "-- installed --"
ls -l /etc/systemd/system-sleep/i8042-resume-fix
echo "-- md5 (must match source) --"
md5sum "$SP/i8042-resume-fix" /etc/systemd/system-sleep/i8042-resume-fix
echo "-- executable as root? --"
[ -x /etc/systemd/system-sleep/i8042-resume-fix ] && echo "yes" || { echo "NO"; exit 1; }
echo "OK"
