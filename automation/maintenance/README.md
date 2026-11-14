# Monthly maintenance

Unattended OS and Pi-hole updates for Pi 1 at **02:00 on the 1st of each month**, with a reboot **only when an update requires one** and a push notification at each step. A boot-time check reports whether the host came back healthy.

## Why

Pi 1 is the DNS server for the whole network, so patching it is a trade-off between staying current and keeping DNS up. Daily `unattended-upgrades` already installs Debian security fixes without rebooting. This job covers the rest: non-security updates, Pi-hole (which does not update through apt), and the reboot that kernel fixes need to take effect, scheduled for when nobody is using the network.

## How it works

| Step | Detail |
|---|---|
| Upgrade | `apt-get full-upgrade` non-interactively (`--force-confold` keeps local config files), `autoremove`, then `pihole -up` |
| Fail safe | If any step fails, the host is **not rebooted**; a failure alert names the step and points to the log |
| Reboot only if needed | Reboots only when `/var/run/reboot-required` exists (normally after a kernel update) |
| Post-reboot verification | A marker file triggers `maintenance-verify.service` once at boot: it checks Pi-hole FTL, Tailscale, the ufw firewall and a DNS lookup, then sends "maintenance complete" or a priority-5 alert |
| No surprise catch-up | `Persistent=false`, so a missed run never fires later in the day |

Logs go to `/var/log/monthly-maintenance.log`. Settings, including the notification topic, live in `/etc/maintenance/maintenance.conf` (root-only, not in this repo).

## Files

| File | Installed to |
|---|---|
| `monthly-maintenance.sh`, `maintenance-verify.sh` | `/usr/local/bin/` |
| `maintenance.conf.example` | `/etc/maintenance/maintenance.conf` (mode 600) |
| `monthly-maintenance.service`, `monthly-maintenance.timer`, `maintenance-verify.service` | `/etc/systemd/system/` |

```bash
sudo systemctl daemon-reload
sudo systemctl enable maintenance-verify.service
sudo systemctl enable --now monthly-maintenance.timer
sudo monthly-maintenance.sh --dry-run     # prints each step, changes nothing
```

## Verification (2026-11-13)

- `shellcheck` clean; `--dry-run` printed every step and changed nothing.
- A supervised real run updated Pi-hole to Core 6.6, Web 6.6.1 and FTL 6.9, found no reboot required, and delivered the "maintenance done" notification to the phone.
- `systemctl list-timers` shows the next run at Tue 2026-12-01 02:00 CST.
