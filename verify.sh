#!/bin/bash
# Suspends to s2idle for 15s, twice, and reports whether the keyboard survived.
set -u
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
for n in 1 2; do
    echo "== cycle $n: suspending for 15s (screen will go dark, it wakes itself) =="
    mark=$(date '+%Y-%m-%d %H:%M:%S')
    rtcwake -m freeze -s 15 >/dev/null 2>&1 || { echo "rtcwake failed"; exit 1; }
    sleep 4
    echo "-- kernel/hook log since suspend --"
    journalctl --since "$mark" --no-pager -o cat 2>/dev/null \
        | grep -iE 'atkbd|i8042-resume-fix|PM: suspend' || echo "(nothing logged)"
    echo "-- keyboard input device present? --"
    grep -c 'AT Translated Set 2 keyboard' /proc/bus/input/devices
    echo
done
echo "== Now TYPE SOMETHING. If characters appear, the fix holds. =="
