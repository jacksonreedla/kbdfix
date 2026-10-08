#!/bin/bash
# Test: does re-running ideapad_laptop's probe restore EC hotkey mode?
FL=/sys/bus/platform/devices/VPC2004:00/fn_lock
echo "before: fn_lock=$(cat $FL 2>/dev/null)"
echo "-- unloading ideapad_laptop --"
modprobe -r ideapad_laptop 2>&1 || { echo "unload failed"; exit 1; }
sleep 1
echo "-- loading ideapad_laptop --"
modprobe ideapad_laptop 2>&1 || { echo "load failed"; exit 1; }
sleep 1
echo "after:  fn_lock=$(cat $FL 2>/dev/null)"
echo "-- module state --"
lsmod | grep -E "^ideapad_laptop"
echo "-- input devices --"
grep -c 'Ideapad extra buttons' /proc/bus/input/devices
echo "-- rfkill (wifi should still be unblocked) --"
rfkill list 2>/dev/null | head -6
