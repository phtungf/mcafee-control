# mcafee-control

Tiny CLI to fully stop / start / check McAfee on macOS, with optional auto-stop on every boot.

## Quick install (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/phtungf/mcafee-control/main/install.sh | sudo bash
```

The installer is interactive and asks:

1. Install `mcafee` command to `/usr/local/bin/mcafee`?
2. Auto-stop McAfee on every macOS boot? (LaunchDaemon at `/Library/LaunchDaemons/com.user.mcafee-autostop.plist`)
3. Run `mcafee stop` immediately?

Press Enter to accept the default (Yes), or type `n` to skip any step.

## Usage

```bash
sudo mcafee stop      # Fully stop McAfee (daemons, agents, processes, system extension)
sudo mcafee start     # Start McAfee back up
mcafee status         # Show current status
```

## What it does

`mcafee stop`:
- Unloads all McAfee LaunchDaemons (`launchctl bootout system ...`)
- Unloads all McAfee LaunchAgents for the current GUI user
- Kills remaining McAfee processes (graceful, then `kill -9`)
- Uninstalls the McAfee system extension if present
- Disables the network extension preference

`mcafee start`:
- Reloads the same daemons and agents via `launchctl bootstrap`

`mcafee status`:
- Lists running McAfee processes

## Auto-stop on boot

If enabled, the LaunchDaemon `com.user.mcafee-autostop` runs `mcafee stop` at every boot. Logs go to `/var/log/mcafee-autostop.log`.

Manage manually:

```bash
sudo launchctl bootout system /Library/LaunchDaemons/com.user.mcafee-autostop.plist   # disable
sudo launchctl bootstrap system /Library/LaunchDaemons/com.user.mcafee-autostop.plist # enable
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/phtungf/mcafee-control/main/uninstall.sh | sudo bash
```

Removes both the `mcafee` binary and the auto-stop LaunchDaemon.

## Manual install

```bash
git clone https://github.com/phtungf/mcafee-control.git
cd mcafee-control
sudo ./install.sh
```

## Notes

- Tested on macOS (Apple Silicon and Intel).
- Requires `sudo` for `stop` / `start`. `status` is read-only.
- This tool only stops McAfee, it does **not** uninstall it. To uninstall McAfee itself, use the official McAfee removal tool.
- Disabling endpoint security may violate your employer's policies. Use at your own risk.

## License

MIT
