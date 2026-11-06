# Pi 1 Hardening: DNS Server and Subnet Router

**Date:** 2026-11-05
**Host:** Pi 1 (Raspberry Pi 5, Raspberry Pi OS / Debian 13 "trixie", Trusted VLAN — 192.168.10.20)
**Roles:** Network-wide DNS filtering (Pi-hole v6) and the Tailscale subnet router for remote access

Pi 1 is the highest-value box on the network: every device in the house depends on it for DNS, and it is the only way in from outside. It was hardened against a written baseline, and every control was verified with a test rather than assumed.

## Baseline and evidence

| Control | What was done | How it was verified |
|---|---|---|
| Remote access | Replaced the WireGuard server (PiVPN) with a Tailscale subnet router. Pi 1 is the only router; no tags, routes approved by hand, key expiry disabled | NAS and Proxmox reachable from an off-site laptop through Pi 1 ([incident report](../incident-reports/2026-11-05-tailscale-subnet-route-conflict.md)) |
| SSH authentication | Key-only login with per-device ed25519 keys (PC and laptop). Password, keyboard-interactive and root login disabled; `MaxAuthTries 3`; `AllowUsers` limited to one account | `sshd -T` shows all three set to `no`; a forced password login is refused with `Permission denied (publickey)` |
| Brute-force protection | fail2ban with an `sshd` jail on the systemd journal | `fail2ban-client status sshd`: jail active, one address already banned |
| Patching | `unattended-upgrades` installing Debian-Security updates daily, with no automatic reboot (so the house never loses DNS unexpectedly) | Dry run lists the allowed origins, including Debian-Security, and the pending security packages |
| DNS integrity | DNSSEC validation turned on in Pi-hole | `dnssec-failed.org` returns `SERVFAIL` (forged answer rejected); `cloudflare.com` returns `NOERROR` |
| Software currency | Pi-hole updated to Core 6.5, Web 6.6.1, FTL 6.8 | `pihole -v` reports every component at its latest version |
| Configuration backup | Pi-hole Teleporter export, kept off the device | Backup archive created and copied to a separate machine |
| Host firewall | ufw installed with a default-deny inbound policy and explicit allows (below) | Staged with all rules in place; to be enabled on site with an automatic rollback timer |

## Planned firewall policy

```
Default: deny (incoming), allow (outgoing)
allow in on tailscale0                      # owner's devices over Tailscale
route allow in on tailscale0 out on eth0    # keeps the subnet route working
allow 53 from 192.168.0.0/16                # DNS for every home VLAN
allow 22/tcp from 192.168.10.0/24           # SSH from the Trusted VLAN only
allow 80/tcp from 192.168.10.0/24           # Pi-hole admin from the Trusted VLAN only
allow 41641/udp                             # Tailscale direct connections
```

The `route allow` line matters: ufw drops forwarded traffic by default, which would silently break the subnet router even though every other service kept working.

## Problems found during hardening

Two controls looked enabled but weren't. Both were caught only because each control was tested, not just configured.

1. **Password SSH was still on.** A hardening file in `/etc/ssh/sshd_config.d/` set `PasswordAuthentication no`, but `sshd -T` still reported `yes`. Raspberry Pi Imager writes `50-cloud-init.conf` with `PasswordAuthentication yes`, and sshd keeps the **first** value it reads, in alphabetical file order. Renaming the hardening file to `01-hardening.conf` fixed it.
2. **Automatic updates were on but installing nothing.** `20auto-upgrades` enabled the daily job, but the policy file `50unattended-upgrades` had been deleted. With no allowed origins, every run found "no packages," while 18 packages were pending. Restored with `apt install --reinstall -o Dpkg::Options::="--force-confmiss" unattended-upgrades`; the next dry run selected the pending security updates.

A side effect was also recorded: installing ufw removed `iptables-persistent` and `netfilter-persistent`. Any saved rules in `/etc/iptables/` are being checked to confirm only the retired WireGuard NAT rules were lost.

## Skills demonstrated

Linux hardening (CIS-style baseline), SSH key management, intrusion prevention with fail2ban, patch management, DNS security (DNSSEC), host firewall design for a router, change control with rollback, and verifying controls with evidence instead of trusting configuration.
