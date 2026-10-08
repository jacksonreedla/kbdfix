#!/bin/bash
# Installs the i8042 resume fix and proves the mechanism works while awake.
set -u
SP="$(cd "$(dirname "$0")" && pwd)"
DRV=/sys/bus/platform/drivers/i8042

[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }

echo "== step 1: does unbind/bind actually restore the keyboard on this machine? =="
before=$(grep -c 'AT Translated Set 2 keyboard' /proc/bus/input/devices)
echo "keyboard input devices before: $before"
printf i8042 > "$DRV/unbind" 2>/dev/null; sleep 0.5
gone=$(grep -c 'AT Translated Set 2 keyboard' /proc/bus/input/devices)
echo "after unbind: $gone   (expect 0)"
printf i8042 > "$DRV/bind" 2>/dev/null; sleep 1
after=$(grep -c 'AT Translated Set 2 keyboard' /proc/bus/input/devices)
echo "after bind:   $after   (expect 1)"
if [ "$after" != "1" ]; then
    echo "FAIL: bind did not bring the keyboard back. Retrying twice..."
    for i in 1 2; do printf i8042 > "$DRV/bind" 2>/dev/null; sleep 1; done
    after=$(grep -c 'AT Translated Set 2 keyboard' /proc/bus/input/devices)
    echo "after retries: $after"
    [ "$after" = "1" ] || { echo "STOP - do not install; keyboard not restored."; exit 1; }
fi
echo "PASS: re-probe restores the keyboard."
grep 'AT Translated Set 2 keyboard' -A2 /proc/bus/input/devices | grep -E 'N:|H:'

echo
echo "== step 2: install the sleep hook =="
install -m 0755 -o root -g root "$SP/i8042-resume-fix" /etc/systemd/system-sleep/i8042-resume-fix
ls -l /etc/systemd/system-sleep/i8042-resume-fix

echo
echo "== done. Now type something to confirm the keyboard works. =="
