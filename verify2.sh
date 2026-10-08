#!/bin/bash
# Suspend through systemd (so sleep hooks actually run), RTC-armed to self-wake.
set -u
[ "$(id -u)" = 0 ] || { echo "must run as root"; exit 1; }
pass=0; fail=0
for n in 1 2 3 4; do
    echo "===== cycle $n: suspending ~25s ====="
    mark=$(date '+%Y-%m-%d %H:%M:%S')
    rtcwake -m no -s 25 >/dev/null 2>&1 || { echo "could not arm RTC alarm"; exit 1; }
    systemctl suspend
    sleep 50
    echo "-- log since suspend --"
    journalctl --since "$mark" --no-pager -o cat 2>/dev/null \
        | grep -iE 'atkbd serio|i8042-resume-fix|PM: suspend' || echo "(nothing)"
    if journalctl --since "$mark" --no-pager 2>/dev/null | grep -q 'i8042-resume-fix.*keyboard present'; then
        echo "RESULT: hook ran and confirmed keyboard present"; pass=$((pass+1))
    else
        echo "RESULT: *** hook did NOT confirm keyboard ***"; fail=$((fail+1))
    fi
    echo "kbd input devices: $(grep -c 'AT Translated Set 2 keyboard' /proc/bus/input/devices)"
    echo
done
echo "===== $pass/4 cycles confirmed by the hook, $fail failed ====="
echo "Now TYPE SOMETHING to confirm the physical keyboard responds."
