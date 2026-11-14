# Home Lab — Self-Hosted Infrastructure & Security Operations Environment

A production home network built from the ground up: enterprise-style VLAN segmentation, a virtualization host, a self-hosted media platform, and a working intrusion detection sensor — built, broken, and fixed by hand.

This repo documents the real build: the architecture, the configs, and the actual incidents encountered and resolved along the way.

---

## Architecture overview

**Network core:** UniFi UCG-Fiber gateway → UniFi Pro XG 8 PoE (10G core switch) → UniFi Flex 2.5G PoE (access switch), with six segmented VLANs enforced by zone-based firewall rules.

| VLAN | Purpose | Subnet | Firewall zone |
|---|---|---|---|
| Management | UniFi infrastructure control plane | 192.168.0.0/24 | Internal |
| Trusted | Personal devices, gaming PC/console | 192.168.10.0/24 | Internal |
| Servers | NAS, hypervisor host, app Pis | 192.168.20.0/24 | Internal |
| IoT | Smart home / streaming devices | 192.168.30.0/24 | IoT (custom zone: internet and gateway only) |
| Guest | Reserved — visitor WiFi | 192.168.40.0/24 | Hotspot |
| Lab | Isolated security sandbox | 192.168.50.0/24 | DMZ |

**Compute:** A Proxmox VE hypervisor host (KAMRUI Hyper H2 mini PC) dedicated to the lab: a planned SIEM, Windows Server/AD, and an isolated attack range as VMs. Media runs separately on the NAS, so lab work never interrupts it.

**Storage:** A 4-bay NAS (UGREEN DXP4800 Plus) running Btrfs-on-RAID5. It also hosts the media stack (Jellyfin, Jellyseerr) in Docker next to the files it serves, and is mounted into Proxmox over SMB/CIFS.

**Edge fleet:** Four Raspberry Pi 5 units, each with a single hardened responsibility:

| Device | Role | Status |
|---|---|---|
| Pi 1 | Network-wide DNS filtering (Pi-hole, DNSSEC) + Tailscale subnet router, hardened ([details](./docs/pi1_hardening.md)) | ✅ Live |
| Pi 2 | Intrusion detection sensor (Suricata, 52,985 active signatures, tuned suppressions) + host firewall (nftables); key-only SSH, fail2ban, automatic security updates, pinned DNS | ✅ Live |
| Pi 3 | Self-hosted apps (Vaultwarden, Nextcloud) | 🔲 Planned |
| Pi 4 | Observability (Grafana + Prometheus + Uptime Kuma) | 🔲 Planned |

**Remote access:** Tailscale (WireGuard-based mesh VPN). Pi 1 is the single subnet router for the Trusted and Servers VLANs; Proxmox and Pi 2 also run Tailscale directly. Access is governed by tailnet access rules (grants) and per-server key-expiry settings, with device approval next on the list. The old WireGuard server (PiVPN) has been removed along with its port forward, so the gateway has **zero port forwards: no inbound ports are open** on the WAN.

---

## What's actually running today

- Multi-VLAN network with a documented, enforced firewall policy (zone-based, least-privilege)
- A verified, alert-generating IDS sensor — see [`incident-reports/`](./incident-reports) for a real detection walkthrough
- Self-hosted media platform (Jellyfin) with request management (Jellyseerr), running in Docker on the NAS
- Hypervisor-backed virtualization with NAS-integrated shared storage
- Remote access via a Tailscale subnet router, replacing the original WireGuard server (double-NAT behind the ISP gateway diagnosed and resolved during the move)
- A hardened DNS and remote-access host: key-only SSH, fail2ban, automatic security patching, DNSSEC and a default-deny host firewall rolled out behind an automatic rollback timer, each verified with a test ([`docs/pi1_hardening.md`](./docs/pi1_hardening.md))
- Real-time alert pipeline: Suricata and UniFi IPS alerts pushed to a phone via ntfy, with benign signatures triaged and suppressed in [`docs/suricata_alert_triage.md`](./docs/suricata_alert_triage.md)

## In progress / roadmap

- SIEM deployment (Wazuh) — centralizing logs from every device above
- Windows Server + Active Directory — identity/access management lab
- An isolated attacker/target pair (Kali + Metasploitable2) for hands-on detection engineering, mapped to MITRE ATT&CK
- Kubernetes (k3s) and Terraform-managed infrastructure — closing the containerization and IaC gap
- A public/hybrid cloud project (Azure or AWS free tier) linked back to this network via Tailscale or WireGuard

Full roadmap and certification mapping: [`docs/gap_closure_roadmap.md`](./docs/gap_closure_roadmap.md)

---

## Incident reports

Real problems, diagnosed and resolved — not staged tutorials.

- [**2026-11-08 — Servers VLAN losing DNS: missing allow, rule-ID ordering, and Pi-hole ignoring routed clients**](./incident-reports/2026-11-08-servers-vlan-dns-failure.md)
- [**2026-11-05 — Remote access to the Servers VLAN failing: duplicate subnet router + a block rule dropping replies**](./incident-reports/2026-11-05-tailscale-subnet-route-conflict.md)
- [**2026-09-27 — Suricata false "no detections" after relocation, root cause: self-referential DNS**](./incident-reports/2026-09-27-suricata-dns-after-move.md)

---

## Diagrams

Full network, rack, and career-mapping diagrams live in [`diagrams/`](./diagrams) — includes physical rack layout, port-level wiring, VLAN/firewall architecture, and the certification coverage map this project was designed against.

---

## Technologies

`Proxmox VE` `UniFi Network` `VLANs & Zone Firewalls` `Tailscale` `WireGuard` `Suricata IDS` `ntfy` `fail2ban` `ufw` `DNSSEC` `nftables` `Pi-hole` `Docker` `Jellyfin` `SMB/CIFS` `Raspberry Pi OS` `Linux Administration`

*(Planned: Wazuh, Windows Server/AD, Kali, Kubernetes, Terraform, Azure/AWS)*
