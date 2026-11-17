# Ansible

Configuration as code for the lab. The control node is WSL Ubuntu on a laptop, reaching hosts over Tailscale with key-based SSH; nothing is installed on the targets beyond Python and SSH.

| Playbook | What it enforces |
|---|---|
| `pi2-baseline.yml` | Security packages present (fail2ban, unattended-upgrades); fail2ban and Suricata running and enabled at boot |
| `maintenance.yml` | Installs the [monthly maintenance job](../automation/maintenance/): scripts, root-only config, systemd units, and a timer at each host's own time |

## Layout

- **One playbook, per-host data.** `maintenance.yml` is the same for every machine. What differs (run time, which services to verify after a reboot, whether to check ufw, which resolver to test, the notification topic) lives in `host_vars/<host>.yml` and is rendered through Jinja2 templates.
- **Handlers** reload systemd only when a unit file actually changed.
- **Secrets stay out of git.** `inventory.ini` and `host_vars/*.yml` are ignored; the `*.example` files show the shape.

## Usage

```bash
cp inventory.example.ini inventory.ini            # set your user
cp host_vars/pi2.example.yml host_vars/pi2.yml    # set your topic
chmod 600 host_vars/pi2.yml
ansible pi2 -m ping                               # connectivity: expect "pong"
ansible-playbook maintenance.yml -K --check       # preview
ansible-playbook maintenance.yml -K               # apply
```

## Verification (2026-11-14)

| Check | Result |
|---|---|
| `ansible pi2 -m ping` | `pong` (SSH, Python 3.13 discovered) |
| `pi2-baseline.yml` against the hand-hardened sensor | `ok=4 changed=0`: the host already matched |
| `maintenance.yml`, first run | Installed the job; only the tasks that needed work reported `changed` |
| `maintenance.yml`, second run | `ok=9 changed=0`: idempotent |
| Timer | Next run Tue 2026-12-01 02:30 CST, staggered 30 minutes after Pi 1 |
| Supervised maintenance run | Kernel 6.18.50 to 6.18.60, two old kernels removed, rebooted; the boot check reported "maintenance complete" (Suricata, alert forwarder, fail2ban, Tailscale and DNS up) about a minute after boot |

## Lessons

- **Host keys first.** The control node keeps its own `known_hosts`; Ansible cannot answer the first-connection prompt, so it fails with "Host key verification failed". Accept the key once with plain `ssh`, and leave `host_key_checking` on.
- **`command` always reports `changed`.** Purpose-built modules (`apt`, `service`, `copy`, `template`) know whether they changed anything; raw commands do not, so playbooks avoid them.
- **Don't reboot under an ad-hoc command.** Starting the maintenance job through Ansible left the connection hanging when the host rebooted. Reboots belong in the `reboot` module, which waits for the host to return.
