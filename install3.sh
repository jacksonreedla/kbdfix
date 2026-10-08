#!/bin/bash
# Install to the directory systemd 255 actually reads, and remove the
# ineffective /etc copy from the previous attempt.
set -euo pipefail
SP="$(cd "$(dirname "$0")" && pwd)"
[ "$(id -u)" = 0 ] || { echo "must run as root"; exit 1; }

rm -f /etc/systemd/system-sleep/i8042-resume-fix
rmdir --ignore-fail-on-non-empty /etc/systemd/system-sleep 2>/dev/null || true

install -m 0755 -o root -g root "$SP/i8042-resume-fix" \
    /usr/lib/systemd/system-sleep/i8042-resume-fix

echo "-- hook directory now --"
ls -l /usr/lib/systemd/system-sleep/
echo "-- md5 must match source --"
md5sum "$SP/i8042-resume-fix" /usr/lib/systemd/system-sleep/i8042-resume-fix
echo "-- stale /etc copy gone? --"
[ -e /etc/systemd/system-sleep/i8042-resume-fix ] && { echo "STILL THERE"; exit 1; } || echo "yes"
echo OK
