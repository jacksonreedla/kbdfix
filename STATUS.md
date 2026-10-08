# F-row media keys broken — investigation status (2026-09-03)

## Symptom
Top-row keys emit plain **F2/F3/F5/F6** instead of volume/brightness.
Captured directly from /dev/input (see keycapture2.py):
    ATKBD press F3 (code 61)   <- should be VOLUMEUP
    ATKBD press F5 (code 63)   <- should be BRIGHTNESSDOWN
Nothing emitted by "Ideapad extra buttons" or "Video Bus" at all.

## Ruled OUT (measured, not assumed)
- Desktop layer fine: csd-media-keys (1780) + csd-power (1782) running;
  bindings = XF86AudioRaiseVolume/LowerVolume/Mute; backlight amdgpu_bl1 present
  (note it sits at 255/255 = max, so brightness-UP looks dead regardless).
- BIOS: HotkeyMode=Enable, FoolProofFnCtrl=Enable (via thinklmi
  /sys/class/firmware-attributes/thinklmi/attributes/). So firmware ALREADY
  wants media keys primary.
- fn_lock=0 and toggling it 0->1->0 changed nothing.
- Reloading ideapad_laptop changed nothing (and soft-blocked wifi as a side
  effect - fixed with `rfkill unblock all`; watch for this if reloading again).

## Open question this reboot answers
Did the i8042 resume hook cause it? The hook unbind/binds i8042 on every
resume, and i8042.reset may knock the EC out of hotkey mode with nothing
re-initialising it.
- Media keys WORK after fresh boot (no suspend)  -> hook is the cause; extend
  the hook to restore EC hotkey mode after the rebind.
- Media keys STILL BROKEN after fresh boot       -> unrelated to the hook;
  investigate EC/BIOS state instead. Do NOT keep patching the hook.

## Test immediately after reboot, BEFORE any lid close
Press volume up/down + brightness down. Then, to confirm either way:
    pkexec /home/apollo/kbdfix/keycapture2.py 60
(prints BIOS/EC state; logs only function/media keys, never typed text)

## Keyboard resume fix (separate issue, WORKING - do not revert)
/usr/lib/systemd/system-sleep/i8042-resume-fix  (source: ~/kbdfix/)
Verified 4/4 suspend cycles, one of which reproduced the fatal
"Failed to enable keyboard" and still recovered.
