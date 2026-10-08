#!/bin/bash
# Re-sync the EC's Fn-lock state. Reported value and actual behaviour have
# diverged: keys emit F2/F3/F5/F6 instead of volume/brightness.
FL=/sys/bus/platform/devices/VPC2004:00/fn_lock
[ -w "$FL" ] || { echo "cannot write $FL"; exit 1; }
echo "before: fn_lock=$(cat $FL)"
echo 1 > "$FL"; sleep 0.3; echo "wrote 1 -> reads $(cat $FL)"
sleep 0.5
echo 0 > "$FL"; sleep 0.3; echo "wrote 0 -> reads $(cat $FL)"
echo "final: fn_lock=$(cat $FL)"
