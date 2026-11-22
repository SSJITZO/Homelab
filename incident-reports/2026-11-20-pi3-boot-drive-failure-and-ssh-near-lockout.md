# Incident Report: Pi 3 Build, SSH Near-Lockout and Boot Drive Failure

**Date:** 2026-11-20 to 2026-11-21
**Affected systems:** Pi 3 `pi3-apps` (Servers VLAN, 192.168.20.30), new build
**Severity:** Low (a host that wasn't in service yet; no data loss and no security exposure)
**Status:** Resolved (2026-11-21)

## Summary

Building Pi 3 hit three problems in a row:

1. **Lost administrator password.** The password set in Raspberry Pi Imager was never saved, so after the cached `sudo` session expired, administrative access was gone. Because the host was new, it was re-imaged.
2. **Near-lockout over SSH.** Imager hadn't installed the SSH public key, so the first login silently used the password. Disabling password authentication as part of hardening would have locked the host out once the open session closed. The still-open session was used to install the key.
3. **Boot drive failure.** The OS was running from a USB flash drive. Mid-session, every command started returning `Input/output error`. After a power cycle the bootloader looped on `xHC-CMD err: 4 type: 11`, unable to read the drive. The host was rebuilt on its NVMe SSD.

## Timeline

| When | Action | Result |
|---|---|---|
| Nov 20, 18:57 | First build complete; `sudo` asked for the password after a long upgrade | Password not in the password manager; administrative access lost |
| 19:07 | Re-imaged with Raspberry Pi OS Lite; the first image had been the desktop edition (desktop packages pulled in by the upgrade) | Clean headless install |
| 20:34 | Applied `01-hardening.conf` (key-only SSH) and verified with `sshd -T` | Settings correct |
| 20:35 | New SSH session from the laptop | `Permission denied (publickey)`: `~/.ssh/authorized_keys` was empty, so the first login had used the password |
| 20:38 | Added the laptop's public key from the still-open session | Key login works; near-lockout avoided |
| 20:52 | Bootloader update and NVMe detection attempts while running from the USB drive | `nvme0n1` not detected |
| 21:02 | `sudo`, `lsblk` and `rpi-eeprom-config` all failed with `Input/output error` | Root filesystem unreadable: the USB drive had dropped off |
| 21:09 | Power cycle; bootloader screen looped on `USB2 root HUB port 1 init`, `xHC-CMD err: 4 type: 11` | Bootloader could not read the drive |
| Nov 21, 11:03 | Re-imaged; `vcgencmd get_throttled` returned `throttled=0x0`; `lsblk` showed `nvme0n1` (119.2 GB) | Power fine; NVMe detected |
| 11:05 | First login again used the password (key missing again); key added **before** hardening | Lockout risk removed before SSH was locked down |
| 11:20 | `BOOT_ORDER=0xf146`, `PCIE_PROBE=1`, `dtparam=pciex1`; cloned the USB drive to the NVMe with `dd`; removed the USB drive | `findmnt /` showed `/dev/nvme0n1p2` |
| 11:40 | Hardening, fail2ban, ufw (with a rollback timer) and Tailscale completed on the NVMe | Baseline verified |

## Root causes

| Problem | Cause |
|---|---|
| Lost password | Password typed into a desktop app; password managers only offer to save web logins |
| Near-lockout | The public-key option in Imager was enabled but the key field didn't hold the key, so no `authorized_keys` was written. The first password login hid this. |
| Boot failure | A consumer USB flash drive used as the root filesystem; it disconnected under sustained writes. Power was ruled out (`throttled=0x0`). |

## What went right

- **The open session was the recovery path.** Keeping the first SSH session open until a second key-based login worked made the near-lockout recoverable without console access.
- **The firewall had a rollback timer.** `systemd-run --on-active=10min ufw disable` would have reverted the host firewall if it had blocked access.
- **The error type pointed at the cause.** `Permission denied (publickey)` is an authentication refusal; a firewall block would have timed out instead. `Input/output error` on basic binaries pointed at the disk, not the configuration.

## Lessons and changes

1. **Prove key login before disabling passwords.** The first SSH login must not ask for a password, and `cat ~/.ssh/authorized_keys` must show the key, before `PasswordAuthentication no` goes in.
2. **Generate and save credentials before using them.** The password manager entry is created first and the password is pasted from it.
3. **No OS on flash drives.** Pi 3 and Pi 4 now boot from NVMe. Removable media is only used to install, then wiped.
4. **Expect `fail2ban` side effects behind a subnet router.** Every remote login reaches the Pis from Pi 1's address, so Pi 1 is on each host's `ignoreip` list.
5. **Placeholders aren't values.** Several commands failed because template text such as `<you>` or `run-XXXX` was run literally. The build doc now names the real value to substitute at each step.

## Related

- [Pi 3 and Pi 4 baseline](../docs/pi3_pi4_baseline.md)
- [2026-11-05: duplicate subnet router](./2026-11-05-tailscale-subnet-route-conflict.md), the reason the new Pis don't advertise routes
