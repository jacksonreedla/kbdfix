#!/bin/bash
# Isolate cause: does the i8042 rebind ALONE break the media keys,
# with no suspend involved?
DRV=/sys/bus/platform/drivers/i8042
FL=/sys/bus/platform/devices/VPC2004:00/fn_lock
show() {
  echo "  serio ports : $(ls /sys/bus/serio/devices/ | tr '\n' ' ')"
  echo "  keyboard    : $(grep -c 'AT Translated Set 2 keyboard' /proc/bus/input/devices)"
  echo "  fn_lock     : $(cat $FL 2>/dev/null)"
}
echo "BEFORE rebind:"; show
echo "-- unbind/bind i8042 (exactly what the resume hook does) --"
printf i8042 > "$DRV/unbind"; sleep 0.5
printf i8042 > "$DRV/bind";   sleep 1
echo "AFTER rebind:"; show
