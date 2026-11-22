# Pi 3 and Pi 4: hardened baseline, NVMe boot and fleet onboarding

**Built:** 2026-11-20 to 2026-11-21
**Hosts:** Pi 3 `pi3-apps` (Servers VLAN, 192.168.20.30) · Pi 4 `pi4-monitor` (Trusted VLAN, 192.168.10.40)
**Hardware:** Raspberry Pi 5 (8 GB) with a 128 GB NVMe SSD on a PCIe HAT

## Roles

| Host | Role | Why it sits where it does |
|---|---|---|
| Pi 3 | Self-hosted apps (Vaultwarden) and a Wazuh agent shipping its logs to the SIEM | Apps live on the Servers VLAN with the NAS and hypervisor. File storage stays on the NAS, so Nextcloud was dropped: it would fill the 128 GB NVMe and duplicate what the NAS already does. |
| Pi 4 | Observability (Prometheus, Grafana, Uptime Kuma, a dashboard), a backup Pi-hole and UPS monitoring (NUT) | DNS belongs on a box that rarely changes, not on the app host that restarts for updates. Pi 4 is on Trusted alongside Pi 1, so it gets the same firewall treatment as the primary DNS server. |

Both hosts got the same baseline before any application work. The applications follow in later sessions.

## Build steps

### 1. Image
Raspberry Pi OS **Lite** (64-bit, Debian 13 "trixie"). Lite has no desktop. These are headless servers managed over SSH, and every package that isn't installed is one less thing to patch or to show up in a vulnerability scan. Imager settings: hostname, admin user, US keyboard, SSH with public-key authentication only, and the laptop's public key pasted into the key field. The admin password is generated in and saved to the password manager **before** it is entered in Imager.

### 2. Boot from NVMe
The OS was installed to a USB drive first, then cloned to the NVMe:

```bash
sudo rpi-eeprom-config --edit          # BOOT_ORDER=0xf146 (NVMe, then USB, then SD) and PCIE_PROBE=1
echo 'dtparam=pciex1' | sudo tee -a /boot/firmware/config.txt
sudo reboot
lsblk                                  # nvme0n1 must be listed
sync
sudo dd if=/dev/sda of=/dev/nvme0n1 bs=4M status=progress conv=fsync
sudo poweroff                          # remove the USB drive, power on
findmnt /                              # /dev/nvme0n1p2
sudo raspi-config                      # Advanced Options > Expand Filesystem
```

`BOOT_ORDER` is read right to left, so `0xf146` tries NVMe first and falls back to USB and SD. The setting lives in each board's own EEPROM, so it has to be set on every Pi. `PCIE_PROBE=1` makes the bootloader look for the NVMe on a non-HAT+ board. The old USB drive is wiped afterwards: it holds an identical copy of the system, and booting with both attached can mount the wrong root partition.

### 3. Patching and security packages
```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y ufw fail2ban unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
sudo unattended-upgrade --dry-run -d | tail -5     # proves the policy file exists and has allowed origins
```

### 4. SSH: key-only
`/etc/ssh/sshd_config.d/01-hardening.conf` (the `01-` prefix matters: sshd keeps the first value it reads):

```
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers <admin-user>
MaxAuthTries 3
X11Forwarding no
```

Checked with `sshd -t`, applied with `systemctl reload ssh`, and verified with `sshd -T`. A second session must log in with the key **before** the first one is closed.

### 5. fail2ban, with the subnet router exempted
```ini
# /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 192.168.10.20

[sshd]
enabled = true
backend = systemd
```

Remote administration arrives over Tailscale through Pi 1, the subnet router, so every remote login looks like it comes from 192.168.10.20. A ban on that address would cut off all remote access through the router, not just one client. The trade-off is acceptable: only authenticated tailnet devices can use that path, and password logins are disabled anyway.

### 6. Host firewall (ufw) with a rollback timer
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.10.0/24 to any port 22 proto tcp     # SSH from Trusted, incl. Tailscale via Pi 1
sudo ufw allow in on tailscale0 to any port 22 proto tcp         # SSH straight over Tailscale
# Pi 4 only, for the backup Pi-hole:
sudo ufw allow from 192.168.0.0/16 to any port 53
sudo ufw allow from 192.168.10.0/24 to any port 80,443 proto tcp
sudo systemd-run --on-active=10min ufw disable                   # safety net
sudo ufw enable
# new SSH session works? then cancel the safety net:
systemctl list-timers 'run-*' --all
sudo systemctl stop run-<id>.timer
```

### 7. Tailscale
Installed directly on both Pis with `tailscale up --accept-dns=false`. They keep using Pi-hole for DNS, and they don't advertise or accept subnet routes: a second subnet router is what broke remote access on 2026-11-05. Key expiry is disabled for these servers. Pi 4 gives a second way into the lab if Pi 1 is down.

### 8. Ansible onboarding
From the control node (WSL Ubuntu): accept each host key once with plain `ssh`, add the host to the inventory with its own `ansible_user`, then:

```bash
ansible pi3 -m ping                               # pong
ansible pi3 -b -K -m command -a "whoami"          # root
ansible pis -m command -a "uptime"                # every Pi answers
```

Pi 1, which had been hardened by hand, was brought into the same inventory, so all four Pis are now managed from one place.

### 9. Monthly maintenance, one playbook for the whole fleet
`maintenance.yml` now targets the `pis` group. What differs per host lives in `host_vars/<host>.yml`:

| Host | Run time (1st of month) | Services checked after a reboot | ufw check | DNS test server |
|---|---|---|---|---|
| Pi 1 | 02:00 | `pihole-FTL tailscaled` | yes | 127.0.0.1 (Pi 1 *is* the resolver) |
| Pi 2 | 02:30 | `suricata suricata-notify fail2ban tailscaled` | no (nftables) | 1.1.1.1 |
| Pi 3 | 02:30 | `fail2ban tailscaled` | yes | 1.1.1.1 |
| Pi 4 | 03:30 | `fail2ban tailscaled` (+ `pihole-FTL` once the backup Pi-hole is installed) | yes | 1.1.1.1 |

Rolled out one host at a time with `--limit`, then tested end to end by starting the job by hand: `ansible pi3 -b -K -m command -a "systemctl start monthly-maintenance.service"`.

## Verification

| Check | Pi 3 | Pi 4 |
|---|---|---|
| Power (`vcgencmd get_throttled`) | `throttled=0x0` | pending check |
| Root filesystem (`findmnt /`) | `/dev/nvme0n1p2`, expanded to 117 GB | pending check |
| `sshd -T` | `passwordauthentication no`, `permitrootlogin no`, `allowusers` set | Key-only: password logins refused (`Permission denied (publickey)`) |
| fail2ban | `sshd` jail running, 0 bans | pending check |
| unattended-upgrades dry run | Runs cleanly, policy present | pending check |
| ufw | Active, deny incoming, SSH from Trusted and on `tailscale0` | Enabled with the rollback timer, timer cancelled after SSH re-tested |
| Tailscale | Online | pending check |
| Ansible | `pong`, `root` | `pong`, `root` |
| Idempotence | `apt name=tree state=present`: first run `CHANGED`, second run `changed: false` | |
| Maintenance job | Supervised run: 0 packages to upgrade, autoremove clean, "done, no reboot needed", phone notification received | Supervised run, phone notification received |
| Next scheduled run | Tue 2026-12-01 02:30 | Tue 2026-12-01 03:30 |

## Lessons

- **Imager's public-key field has to actually contain the key.** On both Pis the first login fell back to the password, which meant the key was never installed. Turning off password authentication at that point would have locked the host out. Check that the first login doesn't ask for a password before hardening SSH. See the [incident report](../incident-reports/2026-11-20-pi3-boot-drive-failure-and-ssh-near-lockout.md).
- **Save the password before you use it.** Password managers don't capture passwords typed into desktop apps like Imager. Generate and save it first, then paste.
- **Don't run an OS from a flash drive.** Pi 3's USB stick dropped off the bus under load (`Input/output error` on every command, then a bootloader loop of `xHC-CMD err: 4 type: 11`). The NVMe is the fix, and keeping the drive's copy unplugged avoids two identical root filesystems.
- **Copied host_vars inherit the wrong host's settings.** Pi 3's and Pi 1's files started as copies of Pi 2's, so they listed Suricata as a service to verify. `--check --diff` against Pi 1 showed this before anything changed.
- **`--check` can't preview a brand-new host past the first service step.** Copy tasks only pretend in check mode, so enabling a unit that hasn't really been installed fails. The boot-check task now skips in check mode.
- **Treat ntfy topics like passwords.** `--diff` prints the rendered config, including the notification URL. Topics that showed up in output are rotated.

## Next

- Pi 4: backup Pi-hole with DHCP handing out both resolvers, then Prometheus, Grafana and Uptime Kuma.
- Pi 3: Wazuh agent (via an Ansible playbook) once the SIEM is up, then Vaultwarden behind the reverse proxy with HTTPS and tested backups.
