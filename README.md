# Home Lab — Self-Hosted Infrastructure & Security Operations Environment

A production home network built from the ground up: enterprise-style VLAN segmentation, a virtualization host, a self-hosted media platform, and a working intrusion detection sensor — built, broken, and fixed by hand.

This repo documents the real build: the architecture, the configs, and the actual incidents encountered and resolved along the way.

---

## Architecture overview

**Network core:** UniFi UCG-Fiber gateway → UniFi Pro XG 8 PoE (10G core switch) → UniFi Flex 2.5G PoE (access switch), with six segmented VLANs enforced by zone-based firewall rules.

| VLAN | Purpose | Subnet |
|---|---|---|
| Management | UniFi infrastructure control plane | 192.168.1.0/24 |
| Trusted | Personal devices, gaming PC/console | 192.168.10.0/24 |
| Servers | NAS, hypervisor host, app Pis | 192.168.20.0/24 |
| IoT | Reserved — smart home / cameras | 192.168.30.0/24 |
| Guest | Reserved — visitor WiFi | 192.168.40.0/24 |
| Lab | Isolated security sandbox | 192.168.50.0/24 |

**Compute:** A Proxmox VE hypervisor host running Jellyfin (media, hardware-transcoded via Intel QuickSync), with a planned SIEM, Windows Server/AD, and an isolated attack range as additional VMs.

**Storage:** A 4-bay NAS (UGREEN DXP4800 Plus) running Btrfs-on-RAID5, mounted into Proxmox over SMB/CIFS.

**Edge fleet:** Four Raspberry Pi 5 units, each with a single hardened responsibility:

| Device | Role | Status |
|---|---|---|
| Pi 1 | Network-wide DNS filtering (Pi-hole) + WireGuard VPN | ✅ Live |
| Pi 2 | Intrusion detection sensor (Suricata, 52,985 active signatures) + host firewall (nftables) | ✅ Live |
| Pi 3 | Self-hosted apps (Vaultwarden, Nextcloud) | 🔲 Planned |
| Pi 4 | Observability (Grafana + Prometheus + Uptime Kuma) | 🔲 Planned |

**Remote access:** WireGuard VPN with the client's traffic routed through the internal DNS filter — no port forwarding beyond a single UDP port, exposed only to the tunnel itself.

---

## What's actually running today

- Multi-VLAN network with a documented, enforced firewall policy (zone-based, least-privilege)
- A verified, alert-generating IDS sensor — see [`incident-reports/`](./incident-reports) for a real detection walkthrough
- Self-hosted media platform (Jellyfin) with request management (Jellyseerr)
- Hypervisor-backed virtualization with NAS-integrated shared storage
- Site-to-site remote access via WireGuard, with double-NAT diagnosed and resolved at the ISP level

## In progress / roadmap

- SIEM deployment (Wazuh) — centralizing logs from every device above
- Windows Server + Active Directory — identity/access management lab
- An isolated attacker/target pair (Kali + Metasploitable2) for hands-on detection engineering, mapped to MITRE ATT&CK
- Kubernetes (k3s) and Terraform-managed infrastructure — closing the containerization and IaC gap
- A public/hybrid cloud project (Azure or AWS free tier) linked back to this network via WireGuard

Full roadmap and certification mapping: [`docs/gap-closure-roadmap.md`](./docs/gap-closure-roadmap.md)

---

## Incident reports

Real problems, diagnosed and resolved — not staged tutorials.

- [**2026-09-27 — Suricata false "no detections" after relocation, root cause: self-referential DNS**](./incident-reports/2026-09-27-suricata-dns-after-move.md)

---

## Diagrams

Full network, rack, and career-mapping diagrams live in [`diagrams/`](./diagrams) — includes physical rack layout, port-level wiring, VLAN/firewall architecture, and the certification coverage map this project was designed against.

---

## Technologies

`Proxmox VE` `UniFi Network` `VLANs & Zone Firewalls` `WireGuard` `Suricata IDS` `nftables` `Pi-hole` `Docker` `Jellyfin` `SMB/CIFS` `Raspberry Pi OS` `Linux Administration`

*(Planned: Wazuh, Windows Server/AD, Kali, Kubernetes, Terraform, Azure/AWS)*
