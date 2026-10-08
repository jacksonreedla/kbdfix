# kbdfix: IdeaPad keyboard dies after suspend

A fix for the Lenovo IdeaPad Slim 3 15ABR8 (82XM) on Linux Mint 22.3, where
the built-in keyboard sometimes comes back dead after closing the lid.

## The problem

After every s2idle resume the kernel logs
`atkbd serio0: Failed to deactivate keyboard on isa0060/serio0`, and on
about one resume in four it also logs
`atkbd serio0: Failed to enable keyboard on isa0060/serio0`. The second one
leaves the keyboard dead until a reboot. `i8042.reset` on the kernel command
line does not help, and `atkbd`/`i8042` are built into the kernel, so they
can't be reloaded with `modprobe`.

## The fix

`i8042-resume-fix` is a systemd sleep hook. After every resume it unbinds and
rebinds the i8042 platform device, which re-runs the controller probe and
recreates the keyboard input device. It was verified across four suspend
cycles, one of which hit the fatal error and still recovered.

## Install

```bash
sudo ./install.sh    # proves unbind/bind restores the keyboard on your machine, then installs
sudo ./install3.sh   # puts the hook in /usr/lib/systemd/system-sleep/
```

systemd 255 only reads sleep hooks from `/usr/lib/systemd/system-sleep/`, not
`/etc/systemd/system-sleep/`. `install3.sh` installs there and removes the
copy an earlier attempt (`install2.sh`) left in `/etc`.

## Other files

- `verify.sh`, `verify2.sh`: check the hook is installed and firing.
- `keycapture.py`, `keycapture2.py`: log function and media keys from
  `/dev/input` to debug the F-row. They drop letters, digits and punctuation
  before writing anything.
- `fnlock.sh`, `reload-ideapad.sh`, `rebind-test.sh`: experiments for a
  separate problem where the F-row sends F2/F3/F5/F6 instead of
  volume/brightness. Notes in `STATUS.md`.

## License

MIT. See [LICENSE](LICENSE).
