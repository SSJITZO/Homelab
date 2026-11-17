# Health checks

A Bash script run by a systemd timer every 5 minutes. It checks the services the lab depends on and sends a phone notification (ntfy) when a check **fails twice in a row**, and once more when it **recovers**. It never repeats an alert while an outage continues.

## Why

On 2026-11-08 DNS on the Servers VLAN had been broken for days and nothing said so ([incident report](../../incident-reports/2026-11-08-servers-vlan-dns-failure.md)). Running services kept working, so the failure stayed silent until an update needed the internet. The `pihole-dns` check below tests that exact path every 5 minutes.

## Design

| Decision | Reason |
|---|---|
| Alert after **2 consecutive failures** | One slow response is a blip, not an outage. A 5-minute gap between runs filters it out |
| Alert on **state change only** (down, then recovered) | A long outage produces one notification instead of one every 5 minutes. Constant repeats teach people to ignore alerts, and trigger rate limits |
| State kept in small files (`/var/lib/healthcheck/`) | Survives reboots; easy to inspect with `ls` and `cat` |
| The alert flag is set only if delivery **succeeded** | If the notification service is unreachable, the next run tries again instead of assuming someone was told |
| Checks listed in a **data file**, not in code | The same script runs on every host; only `checks.list` differs. Adding a check is one line |
| `--dry-run` and `--test-alert` | Test the checks without sending anything; test delivery on its own |
| Timeouts on every check; a `flock` lock | A hung check can never stall the timer or overlap the next run |
| systemd timer, not cron | Every run is logged to the journal; `systemctl list-timers` shows the last and next run |

## Check types

| Type | Arguments | Passes when |
|---|---|---|
| `ping` | host | 2 pings get a reply |
| `tcp` | host port | the port accepts a connection |
| `http` | url [text] | the page loads, and contains the text if one is given |
| `dns` | server name | that server returns an IPv4 address for the name |
| `service` | unit | systemd reports it active |
| `disk` | mount max% | usage is below the limit |
| `fresh` | file seconds | the file was written within that many seconds (catches a log that stopped updating) |

`dig` exits 0 even when it gets no answer, so the DNS check looks for an actual address in the output rather than trusting the exit code.

## Files

| File | Installed to |
|---|---|
| `healthcheck.sh` | `/usr/local/bin/healthcheck.sh` |
| `healthcheck.conf.example` | `/etc/healthcheck/healthcheck.conf` (mode 600; holds the notification topic, kept out of git) |
| `checks.proxmox.list` / `checks.pi2.list` | `/etc/healthcheck/checks.list` on that host |
| `healthcheck.service`, `healthcheck.timer` | `/etc/systemd/system/` |

```bash
healthcheck.sh --dry-run        # run every check, send nothing, change nothing
healthcheck.sh --test-alert     # send one test notification
systemctl enable --now healthcheck.timer
systemctl list-timers healthcheck.timer
journalctl -u healthcheck -n 20
```

## Deployed on

**Proxmox (Servers VLAN)**, checking: internet reachability, Pi-hole DNS across the VLAN boundary, public DNS, the NAS admin page, Jellyfin's `/health` endpoint (must return `Healthy`), the Proxmox UI and root disk usage.

## Verification

| Date | Test | Result |
|---|---|---|
| 2026-11-13 | `shellcheck`; simulated outage against a local fake notification server | Clean; one alert at the second failure, none while it stayed down, one on recovery |
| 2026-11-13 | First dry run on Proxmox | 6/7: Jellyfin timed out once (slow first response) and showed `[1/2]`. The next request returned 200. **The two-failure threshold held: no false alert** |
| 2026-11-13 | Test alert | Revealed the config pointed at the wrong notification topic. Moved to a dedicated operations topic, separate from security alerts |
| 2026-11-13 | After enabling the Pi 1 host firewall and rebooting it | 7/7, including Pi-hole DNS from the Servers VLAN |
| **2026-11-17** | **Stopped the Jellyfin container on purpose**, ran the check twice, then restarted it | **"jellyfin DOWN" arrived on the phone at the second failure; "jellyfin recovered" arrived after the restart.** No repeat alerts in between |

## Next

- Deploy to Pi 2 (`checks.pi2.list`: Suricata running, `eve.json` still being written, fail2ban, pinned DNS, the alert forwarder, disk) through the [Ansible](../../ansible) setup
- A daily "all OK" heartbeat, so silence always means something is wrong rather than "probably fine"
