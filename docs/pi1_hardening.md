# Pi 1 Hardening: DNS Server and Subnet Router

**Date:** 2026-11-05 (firewall enabled 2026-11-13)
**Host:** Pi 1 (Raspberry Pi 5, Raspberry Pi OS / Debian 13 "trixie", Trusted VLAN — 192.168.10.20)
**Roles:** Network-wide DNS filtering (Pi-hole v6) and the Tailscale subnet router for remote access

Pi 1 is the highest-value box on the network: every device in the house depends on it for DNS, and it is the only way in from outside. It was hardened against a written baseline, and every control was verified with a test rather than assumed.

## Baseline and evidence

| Control | What was done | How it was verified |
|---|---|---|
| Remote access | Replaced the WireGuard server (PiVPN) with a Tailscale subnet router. Pi 1 is the only router; no tags, routes approved by hand, key expiry disabled | NAS and Proxmox reachable from an off-site laptop through Pi 1 ([incident report](../incident-reports/2026-11-05-tailscale-subnet-route-conflict.md)); nothing listening on UDP 51820, no `wg0` interface, zero port forwards on the gateway |
| SSH authentication | Key-only login with per-device ed25519 keys (PC and laptop). Password, keyboard-interactive and root login disabled; `MaxAuthTries 3`; `AllowUsers` limited to one account | `sshd -T` shows all three set to `no`; a forced password login is refused with `Permission denied (publickey)` |
| Brute-force protection | fail2ban with an `sshd` jail on the systemd journal | `fail2ban-client status sshd`: jail active, one address already banned |
| Patching | `unattended-upgrades` installing Debian-Security updates daily, with no automatic reboot (so the house never loses DNS unexpectedly); plus a [monthly maintenance job](../automation/maintenance/) at 02:00 on the 1st for the full upgrade, Pi-hole and any reboot an update needs | Dry run lists the allowed origins, including Debian-Security, and the pending security packages; the monthly job's first supervised run updated Pi-hole and reported to the phone |
| DNS scope | Listening mode changed from `LOCAL` to `ALL` so every home VLAN can resolve through Pi-hole; exposure is controlled by the network instead (zero port forwards, UniFi zone policies, and the host firewall below) | `nslookup` from the Servers VLAN returns an answer, and `tcpdump` on Pi 1 shows the query in and the reply out ([incident report](../incident-reports/2026-11-08-servers-vlan-dns-failure.md)) |
| DNS integrity | DNSSEC validation turned on in Pi-hole | `dnssec-failed.org` returns `SERVFAIL` (forged answer rejected); `cloudflare.com` returns `NOERROR` |
| Software currency | Pi-hole kept current by the monthly job (Core 6.6, Web 6.6.1, FTL 6.9 as of 2026-11-13) | The job's log reports every component at its latest version |
| Configuration backup | Pi-hole Teleporter export, kept off the device | Backup archive created and copied to a separate machine |
| Host firewall | ufw enabled with a default-deny inbound and routed policy and explicit allows (below), rolled out on site behind an automatic rollback timer | Five access tests run before the rollback was cancelled (below) |

## Firewall policy (enabled 2026-11-13)

```
Default: deny (incoming), allow (outgoing), deny (routed)
allow in on tailscale0                      # owner's devices over Tailscale
route allow in on tailscale0 out on eth0    # keeps the subnet route working
allow 53 from 192.168.0.0/16                # DNS for every home VLAN
allow 22/tcp from 192.168.10.0/24           # SSH from the Trusted VLAN only
allow 80/tcp from 192.168.10.0/24           # Pi-hole admin from the Trusted VLAN only
```

The `route allow` line matters: ufw drops forwarded traffic by default, which would silently break the subnet router even though every other service kept working.

### Rollout with a rollback timer

Pi 1 is the only way into the network from outside, so a wrong rule could lock out every remote session. The change was made on site, with a timer that switches the firewall off again if nobody cancels it:

```bash
sudo systemd-run --on-active=10min ufw disable   # automatic rollback in 10 minutes
sudo ufw enable
# ...run the access tests, keeping the original session open...
sudo systemctl stop run-<id>.timer               # cancel the rollback once every test passes
```

### Verification

| Test | From | Result |
|---|---|---|
| Rules loaded as designed | Pi 1 (`ufw status verbose`) | Default deny incoming and routed; five allows as above |
| DNS lookup | Laptop on the Management VLAN (`nslookup example.com 192.168.10.20`) | Answered: DNS is open to every home VLAN |
| SSH and Pi-hole admin, direct | Laptop on the Management VLAN | Timed out, as intended: only the Trusted VLAN may reach them |
| SSH and Pi-hole admin, over Tailscale | Same laptop with Tailscale connected | Both work: traffic arrives on `tailscale0` |
| Remote access from outside | Phone on mobile data with Tailscale | Pi-hole admin loads |
| Survives a reboot | Pi 1, after a full OS upgrade (kernel 6.18.34 to 6.18.60) and reboot | Firewall active, Pi-hole FTL active and Tailscale online with no manual steps; SSH back in over Tailscale |

The blocked direct test was a useful finding rather than a fault. The house Wi-Fi access point currently places its clients on the Management VLAN, so admin access from Wi-Fi now goes through Tailscale, which is one authenticated path. Moving Wi-Fi to UniFi access points with a Trusted SSID will restore direct access from personal devices without widening the firewall.

**Defence in depth for DNS:** Pi-hole answers queries from every origin, but three independent layers stop anything outside the house from using it: zero port forwards on the gateway, the UniFi zone policies, and this host firewall.

## Problems found during hardening

Two controls looked enabled but weren't. Both were caught only because each control was tested, not just configured.

1. **Password SSH was still on.** A hardening file in `/etc/ssh/sshd_config.d/` set `PasswordAuthentication no`, but `sshd -T` still reported `yes`. Raspberry Pi Imager writes `50-cloud-init.conf` with `PasswordAuthentication yes`, and sshd keeps the **first** value it reads, in alphabetical file order. Renaming the hardening file to `01-hardening.conf` fixed it.
2. **Automatic updates were on but installing nothing.** `20auto-upgrades` enabled the daily job, but the policy file `50unattended-upgrades` had been deleted. With no allowed origins, every run found "no packages," while 18 packages were pending. Restored with `apt install --reinstall -o Dpkg::Options::="--force-confmiss" unattended-upgrades`; the next dry run selected the pending security updates.

A side effect was also recorded: installing ufw removed `iptables-persistent` and `netfilter-persistent`, so the rules saved in `/etc/iptables/` are no longer loaded at boot. The saved file was reviewed: apart from one DNS allow on the retired WireGuard interface (`wg0`), every rule belonged to Tailscale, which rebuilds its own chains each time it starts. Nothing in use was lost, which the reboot test confirmed.

## Skills demonstrated

Linux hardening (CIS-style baseline), SSH key management, intrusion prevention with fail2ban, patch management, DNS security (DNSSEC), host firewall design for a router, change control with rollback, and verifying controls with evidence instead of trusting configuration.
