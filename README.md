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

## Known limitation: McAfee Network Extension survives `stop`

After `sudo mcafee stop`, `mcafee status` may still show one process:

```
McAfee: RUNNING (1 process(es))
  PID xxxxx  CPU 0.0  /Library/SystemExtensions/.../com.mcafee.CMF.networkextension
```

This is the **McAfee Network Extension** (a macOS *System Extension*). It runs under the launchd label `<teamID>.com.mcafee.CMF.networkextension` and is protected by **System Integrity Protection (SIP)**. With SIP enabled, macOS refuses every removal path from user space:

| Attempt | Result |
| --- | --- |
| `kill -9 <pid>` | Process respawns immediately (sysextd) |
| `launchctl bootout system/<label>` | `Boot-out failed: 1: Operation not permitted` |
| `launchctl disable system/<label>` | Silently ignored |
| `systemextensionsctl uninstall <teamID> <bundleID>` | `At this time, this tool cannot be used if System Integrity Protection is enabled.` |

This is by design — Apple explicitly prevents user-space tools (including root) from disabling endpoint-security extensions, so malware cannot disable AV products.

**The good news:** the surviving extension sits at ~0.0% CPU. All the heavy McAfee daemons (real-time scan, on-access scan, periodic scan, firewall, VPN, product update, DAT update, cloud SDK, menulet, etc.) are fully stopped, which is what was actually consuming resources.

### If you really need to remove the network extension

You have to take SIP out of the picture. Two options:

**Option A — temporarily disable SIP, uninstall, re-enable** (not recommended for daily use):

1. Reboot into Recovery (Apple Silicon: hold power; Intel: hold ⌘R during boot).
2. Open Terminal → `csrutil disable` → reboot.
3. Back in macOS:
   ```bash
   sudo systemextensionsctl uninstall GT8P3H7SPW com.mcafee.CMF.networkextension
   ```
   (Replace `GT8P3H7SPW` with your teamID from `systemextensionsctl list | grep mcafee`.)
4. Reboot into Recovery again → `csrutil enable` → reboot.

**Option B — use the official McAfee uninstaller** (preferred). The McAfee installer is registered with the system extension and is allowed to deactivate it cleanly. On a corporate machine this will likely be flagged by IT.

If your employer manages the device via MDM and the extension was installed by a configuration profile, you also need to remove that profile (`profiles list | grep mcafee` to check). On managed machines this typically requires IT approval.

## License

MIT
