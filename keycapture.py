#!/usr/bin/env python3
"""Capture EV_KEY events from the AT keyboard, Ideapad extra buttons, Video Bus."""
import os, select, struct, sys, time

FMT = 'qqHHi'
SZ = struct.calcsize(FMT)
EV_KEY = 0x01

NAMES = {
    1: 'ESC', 29: 'LEFTCTRL', 56: 'LEFTALT',
    59: 'F1', 60: 'F2', 61: 'F3', 62: 'F4', 63: 'F5', 64: 'F6',
    65: 'F7', 66: 'F8', 67: 'F9', 68: 'F10', 87: 'F11', 88: 'F12',
    113: 'MUTE', 114: 'VOLUMEDOWN', 115: 'VOLUMEUP',
    224: 'BRIGHTNESSDOWN', 225: 'BRIGHTNESSUP',
    248: 'MICMUTE', 212: 'CAMERA', 238: 'WLAN',
    142: 'SLEEP', 152: 'SCREENLOCK', 226: 'MEDIA',
    464: 'FN', 372: 'FN_ESC',
}


def name(code):
    return NAMES.get(code, f'code{code}')


def targets():
    out = []
    with open('/proc/bus/input/devices') as f:
        blocks = f.read().split('\n\n')
    for b in blocks:
        if 'AT Translated Set 2 keyboard' in b:
            label = 'ATKBD'
        elif 'Ideapad extra buttons' in b:
            label = 'IDEAPAD'
        elif 'Video Bus' in b:
            label = 'VIDEOBUS'
        else:
            continue
        for tok in b.split():
            if tok.startswith('event'):
                out.append(('/dev/input/' + tok, label))
    return out


def main():
    dur = int(sys.argv[1]) if len(sys.argv) > 1 else 45
    tgts = targets()
    if not tgts:
        print('no target devices found')
        return 1
    devs = {}
    for path, label in tgts:
        try:
            devs[os.open(path, os.O_RDONLY | os.O_NONBLOCK)] = label
        except OSError as e:
            print('cannot open %s: %s' % (path, e))
    if not devs:
        print('could not open any device (need root)')
        return 1
    print('watching: ' + ', '.join('%s=%s' % (l, p) for p, l in tgts), flush=True)
    print('>>> PRESS VOLUME UP/DOWN AND BRIGHTNESS UP/DOWN NOW - listening %ds <<<' % dur,
          flush=True)
    end = time.time() + dur
    seen = 0
    while time.time() < end:
        ready, _, _ = select.select(list(devs), [], [], 0.5)
        for fd in ready:
            try:
                data = os.read(fd, SZ * 64)
            except OSError:
                continue
            for i in range(0, len(data) - SZ + 1, SZ):
                _, _, etype, code, val = struct.unpack(FMT, data[i:i + SZ])
                if etype == EV_KEY and val in (0, 1):
                    print('  [%-8s] %-7s %s (code %d)'
                          % (devs[fd], 'press' if val else 'release', name(code), code),
                          flush=True)
                    seen += 1
    print('-- done, %d key events captured --' % seen, flush=True)
    return 0


sys.exit(main())
