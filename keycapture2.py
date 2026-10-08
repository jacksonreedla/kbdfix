#!/usr/bin/env python3
"""Capture ONLY function/media keys - never letters, digits or punctuation.

Privacy: keycodes 1-58 (esc, digits, letters, punctuation, backspace, tab,
enter, modifiers, space, capslock), 69-85 (locks + keypad) and 96-111 (keypad
enter, arrows, navigation) are dropped before anything is written down.
"""
import os, select, struct, sys, time

FMT = 'qqHHi'
SZ = struct.calcsize(FMT)
EV_KEY = 0x01

EXCLUDE = set(range(1, 59)) | set(range(69, 86)) | set(range(96, 112))

NAMES = {
    59: 'F1', 60: 'F2', 61: 'F3', 62: 'F4', 63: 'F5', 64: 'F6', 65: 'F7',
    66: 'F8', 67: 'F9', 68: 'F10', 87: 'F11', 88: 'F12',
    113: 'MUTE', 114: 'VOLUMEDOWN', 115: 'VOLUMEUP',
    224: 'BRIGHTNESSDOWN', 225: 'BRIGHTNESSUP',
    248: 'MICMUTE', 212: 'CAMERA', 238: 'WLAN', 142: 'SLEEP',
    152: 'SCREENLOCK', 226: 'MEDIA', 464: 'FN', 372: 'FN_ESC',
    431: 'FN_LOCK?', 148: 'PROG1', 149: 'PROG2',
}


def name(c):
    return NAMES.get(c, 'code%d' % c)


def state():
    out = []
    for p in ('/sys/bus/platform/devices/VPC2004:00/fn_lock',):
        try:
            out.append('fn_lock=' + open(p).read().strip())
        except OSError:
            out.append('fn_lock=?')
    for attr in ('HotkeyMode', 'FoolProofFnCtrl'):
        p = '/sys/class/firmware-attributes/thinklmi/attributes/%s/current_value' % attr
        try:
            out.append('%s=%s' % (attr, open(p).read().strip()))
        except OSError as e:
            out.append('%s=<%s>' % (attr, e.__class__.__name__))
    return '  '.join(out)


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
    dur = int(sys.argv[1]) if len(sys.argv) > 1 else 300
    print('BIOS/EC state: ' + state(), flush=True)
    tgts = targets()
    devs = {}
    for path, label in tgts:
        try:
            devs[os.open(path, os.O_RDONLY | os.O_NONBLOCK)] = label
        except OSError as e:
            print('cannot open %s: %s' % (path, e), flush=True)
    if not devs:
        print('could not open any device (need root)')
        return 1
    print('watching: ' + ', '.join('%s=%s' % (l, p) for p, l in tgts), flush=True)
    print('press volume up/down and brightness up/down whenever you like '
          '(%ds window); typing is NOT recorded' % dur, flush=True)
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
                if etype != EV_KEY or val not in (0, 1) or code in EXCLUDE:
                    continue
                print('  %-8s %-7s %s (code %d)'
                      % (devs[fd], 'press' if val else 'release', name(code), code),
                      flush=True)
                seen += 1
    print('-- done, %d function/media key events captured --' % seen, flush=True)
    print('BIOS/EC state at end: ' + state(), flush=True)
    return 0


sys.exit(main())
