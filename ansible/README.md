# Ansible

Configuration as code for the lab. The control node is WSL Ubuntu on a laptop, reaching hosts over Tailscale with key-based SSH; nothing is installed on the targets beyond Python and SSH.

| Playbook | What it enforces |
|---|---|
| `pi2-baseline.yml` | Security packages present (fail2ban, unattended-upgrades); fail2ban and Suricata running and enabled at boot |
| `maintenance.yml` | Installs the [monthly maintenance job](../automation/maintenance/) on all four Pis: scripts, root-only config, systemd units, and a timer at each host's own time |

**Managed hosts:** Pi 1 (DNS + subnet router), Pi 2 (IDS sensor), Pi 3 (apps), Pi 4 (monitoring).

## Layout

- **One playbook, per-host data.** `maintenance.yml` is the same for every machine. What differs (run time, which services to verify after a reboot, whether to check ufw, which resolver to test, the notification topic) lives in `host_vars/<host>.yml` and is rendered through Jinja2 templates.
- **Handlers** reload systemd only when a unit file actually changed.
- **Secrets stay out of git.** `inventory.ini` and `host_vars/*.yml` are ignored; the `*.example` files show the shape.

## Usage

```bash
cp inventory.example.ini inventory.ini            # set your users
cp host_vars/pi3.example.yml host_vars/pi3.yml    # one per host; set your topic
chmod 600 host_vars/*.yml
ssh <user>@192.168.20.30                          # accept the host key once, then exit
ansible pi3 -m ping                               # connectivity: expect "pong"
ansible pi3 -b -K -m command -a "whoami"          # privilege escalation: expect "root"
ansible-playbook maintenance.yml -K --limit pi3 --check --diff   # preview one host
ansible-playbook maintenance.yml -K --limit pi3                  # apply one host
```

`--diff` prints the rendered config, including the notification URL, so don't share its output.

## Verification (2026-11-14)

| Check | Result |
|---|---|
| `ansible pi2 -m ping` | `pong` (SSH, Python 3.13 discovered) |
| `pi2-baseline.yml` against the hand-hardened sensor | `ok=4 changed=0`: the host already matched |
| `maintenance.yml`, first run | Installed the job; only the tasks that needed work reported `changed` |
| `maintenance.yml`, second run | `ok=9 changed=0`: idempotent |
| Timer | Next run Tue 2026-12-01 02:30 CST, staggered 30 minutes after Pi 1 |
| Supervised maintenance run | Kernel 6.18.50 to 6.18.60, two old kernels removed, rebooted; the boot check reported "maintenance complete" (Suricata, alert forwarder, fail2ban, Tailscale and DNS up) about a minute after boot |

## Verification (2026-11-21): Pi 1, Pi 3 and Pi 4 added

| Check | Result |
|---|---|
| `ansible pis -m command -a "uptime"` | All four Pis answer in one run |
| Idempotence on Pi 3 | `apt name=tree state=present`: first run `CHANGED`, second run `"changed": false` |
| `maintenance.yml --limit pi3` (new host) | `ok=10 changed=8 failed=0`; timer set for Tue 2026-12-01 |
| Supervised run on Pi 3 | 0 packages to upgrade, "done, no reboot needed", phone notification received |
| `maintenance.yml --limit pi1 --check --diff` (hand-installed host) | Showed the exact config and timer differences before the switch to Ansible; caught wrong verify settings (below) |
| Pi 4 | Onboarded the same way; supervised run delivered the phone notification |

## Lessons

- **Host keys first.** The control node keeps its own `known_hosts`; Ansible cannot answer the first-connection prompt, so it fails with "Host key verification failed". Accept the key once with plain `ssh`, and leave `host_key_checking` on.
- **`command` always reports `changed`.** Purpose-built modules (`apt`, `service`, `copy`, `template`) know whether they changed anything; raw commands do not, so playbooks avoid them.
- **Copied host_vars carry the wrong host's settings.** Pi 3's and Pi 1's files started as copies of Pi 2's, so they listed Suricata among the services to verify after a reboot. `--check --diff` caught it on Pi 1 before anything changed. Each host now has its own example file.
- **`--check` can't fully preview a brand-new host.** Copy tasks only simulate in check mode, so enabling a unit that isn't really installed fails. The boot-check task now skips in check mode.
- **Every inventory host needs its own user.** Usernames differ per Pi, so each line sets `ansible_user`.
- **Don't reboot under an ad-hoc command.** Starting the maintenance job through Ansible left the connection hanging when the host rebooted. Reboots belong in the `reboot` module, which waits for the host to return.
