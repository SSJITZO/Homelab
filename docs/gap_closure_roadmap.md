# Gap Closure Roadmap
### Every remaining gap, in build order, with concrete first steps

This is the execution plan for everything flagged as a gap in the Career Pathway Map. Each section tells you what to install, where it lives, and what it proves. Build order matters — earlier items unlock or feed later ones.

---

## BUILD 1 — SIEM (Wazuh) — closes: Security+, CySA+, Cloud+ security domain

**What:** A VM on Proxmox running Wazuh, collecting logs from Suricata (Pi 2), Pi-hole (Pi 1), and eventually every other device.

**High-level steps:**
1. Create a new VM in Proxmox — Ubuntu Server 22.04 LTS, 4 vCPU / 8GB RAM / 50GB disk minimum
2. Install Wazuh via their all-in-one install script
3. Access the Wazuh dashboard, confirm it's reachable on your Servers VLAN
4. Install the Wazuh agent on Pi 1, Pi 2, Pi 3, Pi 4 — each ships its logs to the SIEM
5. Configure Suricata's `eve.json` to feed into Wazuh specifically (a filebeat/log-forwarding config)
6. Confirm data is arriving — generate a test event, watch it appear in the dashboard
7. Build your first custom dashboard/alert rule

**Proves:** SIEM operations, log correlation, alert triage — the single most-requested SOC skill.

---

## BUILD 2 — Windows Server + Active Directory — closes: Security+, Network+, Oracle IAM path

**What:** A VM on Proxmox running Windows Server, configured as a domain controller.

**High-level steps:**
1. Create a VM in Proxmox — Windows Server 2022 Evaluation (free, 180-day license, renewable), 2 vCPU / 4GB RAM / 60GB disk
2. Install the OS, then add the **Active Directory Domain Services** role
3. Promote it to a domain controller, create a new forest (e.g., `homelab.local`)
4. Create Organizational Units, users, and security groups
5. Build at least one Group Policy Object (GPO) — e.g., password complexity requirements
6. Join a client VM (a small Windows 10/11 or Linux-with-realmd VM) to the domain
7. Point Wazuh at the domain controller's event logs — this is a real log source SOCs care about

**Proves:** Identity and access management, directory services, Windows administration — directly relevant to the Oracle IAM Analyst lateral path.

---

## BUILD 3 — Kali + Vulnerable Target (the attack range) — closes: Security+, portfolio centerpiece for all tracks

**What:** Two VMs on Proxmox — an attacker (Kali Linux) and a victim (an intentionally vulnerable machine).

**High-level steps:**
1. Create a Kali Linux VM on Proxmox (official ISO, free)
2. Create a target VM — **Metasploitable2** (pre-built vulnerable Linux image) is the easiest starting point
3. Put both on the isolated **Lab VLAN (50)** — never let this traffic touch production
4. From Kali, run a basic scan against the target: `nmap -sV <target-IP>`
5. Attempt a known exploit against Metasploitable2 (there are well-documented walkthroughs — e.g., the vsftpd backdoor)
6. Confirm Suricata (Pi 2) generates an alert for the attack traffic
7. Confirm that alert flows into Wazuh (Build 1)
8. **Write it up** — this document (attack → detection → SIEM alert → your analysis) is your single best portfolio artifact

**Proves:** Offensive basics, detection engineering, and — critically — the full attack lifecycle from a defender's seat. This is the project every SOC interview wants to hear about.

---

## BUILD 4 — MITRE ATT&CK mapping — closes: Security+, CySA+ (ongoing practice, not a one-time build)

**What:** A habit, not a separate system — every time you detect something in Build 3 (or later, in production), identify which ATT&CK technique it represents.

**How to do it:**
1. Bookmark **attack.mitre.org**
2. For each Suricata/Wazuh alert you investigate, look up the matching technique ID (e.g., T1046 = Network Service Discovery, for the nmap scan in Build 3)
3. Note it in your write-up: *"Detected T1046 (Network Service Discovery) via Suricata signature X, confirmed in Wazuh alert Y"*

**Proves:** Structured threat analysis — a specific, checkable skill that separates candidates who *understand* detections from those who just click alerts.

---

## BUILD 5 — k3s (Kubernetes) — closes: Cloud+ containerization objective

**What:** A lightweight Kubernetes cluster, either across your Pi 3/4 or as small Proxmox VMs.

**High-level steps:**
1. Decide placement — either 2-3 small Proxmox VMs (recommended, more headroom) or repurpose part of Pi 3/4's role
2. Install k3s on the first node as the server: `curl -sfL https://get.k3s.io | sh -`
3. Join additional nodes as agents using the server's token
4. Confirm the cluster: `kubectl get nodes`
5. Deploy something simple first — e.g., a basic nginx pod — to confirm the cluster actually works
6. **Stretch goal:** migrate one existing Docker service (like Jellyseerr) into the k3s cluster as a real workload

**Proves:** Container orchestration — now a core Cloud+ objective, and a strong general resume line regardless of track.

---

## BUILD 6 — Terraform (Infrastructure as Code) — closes: Cloud+ IaC objective

**What:** Managing at least one Proxmox VM through code instead of clicking through the GUI.

**High-level steps:**
1. Install Terraform on your everyday computer (not a Pi/server)
2. Install the **Telmate/proxmox** or **bpg/proxmox** Terraform provider
3. Generate an API token in Proxmox for Terraform to authenticate with
4. Write a small `.tf` file defining one VM (e.g., a throwaway test VM)
5. `terraform init`, `terraform plan`, `terraform apply` — watch it create the VM automatically
6. `terraform destroy` it, then recreate it — this loop is the whole point: infrastructure that's reproducible from code

**Proves:** Infrastructure as Code — directly tested on Cloud+, and the actual way modern cloud/DevOps teams manage infrastructure.

---

## BUILD 7 — AWS or Azure free-tier hybrid project — closes: Cloud+ public/hybrid cloud objective

**What:** One small project connecting your homelab to a real public cloud account.

**High-level steps:**
1. Create an Azure account (recommended — Always-Free tier never expires) or AWS account
2. Set a billing alert at $1 immediately, before doing anything else
3. Spin up the smallest free-tier VM available (Azure B1S, or AWS t2/t3.micro)
4. Join the cloud VM to the tailnet (or build a WireGuard site-to-site tunnel to it, for the hands-on VPN practice) — now your homelab and the cloud VM can reach each other securely
5. **Optional stretch:** host something trivial on the cloud VM (a status page, a small web app) that's only reachable through that tunnel
6. Document it as a genuine hybrid-cloud project
7. **Delete/stop the resource when you're done experimenting** to avoid drift into paid usage

**Proves:** Public cloud fundamentals and hybrid connectivity — the one thing no on-prem-only homelab can otherwise demonstrate.

---

## BUILD 8 — OCI free-tier instance — closes: Oracle-specific track

**What:** A free Oracle Cloud Infrastructure compute instance, since you work at Oracle and this is disproportionately valuable to you specifically.

**High-level steps:**
1. Sign up for OCI's **Always Free tier** (genuinely permanent, unlike AWS/Azure's time-limited free credits)
2. Spin up a free-tier compute instance (ARM Ampere A1 instances are generous on the free tier)
3. Mirror one small homelab service there — e.g., join it to the tailnet as a second subnet router, or host a simple monitoring page
4. Get comfortable navigating the OCI console specifically — compute, VCN (their term for VPC/networking), IAM
5. Pair this with studying for the **OCI Foundations Associate** exam (free to sit, fast to prepare for)

**Proves:** Genuine OCI hands-on experience — directly relevant to internal Oracle infrastructure roles, and a credential very few external candidates bother getting.

---

## BUILD 9 — Cisco Packet Tracer recreation — closes: Network Engineer CLI/CCNA gap

**What:** Your existing network topology, rebuilt in Cisco IOS syntax. *(Already scoped in an earlier session — device list and IP scheme are ready.)*

**High-level steps:**
1. Install Packet Tracer (free via Cisco Networking Academy signup)
2. Recreate your topology using the device list already mapped: 2x router (gateway + ISP), 2x switch (core + access), servers, PCs
3. Configure VLANs via CLI (`vlan 10`, `name Trusted`, etc.) matching your real scheme
4. Configure trunk ports and router-on-a-stick subinterfaces for inter-VLAN routing
5. Translate your real UniFi firewall rules into Cisco ACLs
6. **Stretch goal:** add OSPF between two routers to practice the dynamic routing protocol gap Network+/CCNA test

**Proves:** Cisco IOS command-line fluency — the one thing your GUI-based UniFi network genuinely can't teach, and what CCNA/CCNP actually examine.

---

## BUILD 10 — Proxmox Backup Server — closes: Cloud+ (availability / DR), Security+ (resilience)

**What:** A dedicated backup server for every Proxmox VM, storing deduplicated, encrypted backups on the NAS.

**High-level steps:**
1. Install Proxmox Backup Server on a second mini PC (a Lenovo ThinkCentre M720q is planned), not on the host it protects
2. Create a datastore on an NFS share on the NAS that only the backup server can reach
3. Add it to Proxmox as storage, with client-side encryption (keep the key off the lab)
4. Schedule nightly backups with a 7 daily / 4 weekly / 3 monthly retention, plus weekly verify jobs
5. Do a test restore every month: restore a VM to a new ID, boot it, delete the copy

**Proves:** Backup and recovery you have actually tested, the control that decides whether a ransomware incident is a bad day or a disaster.

---

## BUILD 11 — Vulnerability scanning (Greenbone / OpenVAS) — closes: CySA+ vulnerability management

**What:** Scheduled scans of your own network, followed by fixing what they find.

**High-level steps:**
1. Deploy Greenbone Community Edition (official containers) on the second node
2. Allow only the scanner to reach every VLAN, with a single firewall rule
3. Run an unauthenticated scan, then an authenticated one with a dedicated SSH key
4. Rank findings by severity, fix the top ones, rescan, and keep the before/after reports

**Proves:** The full vulnerability-management cycle (scan, prioritize, remediate, verify), a large share of the CySA+ exam.

---

## BUILD 12 — Reverse proxy + internal TLS — closes: Security+ (PKI / TLS), Network+

**What:** Clean HTTPS names (`proxmox.home.arpa`, `nas.home.arpa`) for every web UI, instead of IP addresses and certificate warnings.

**High-level steps:**
1. Run Nginx Proxy Manager in a small container, with its admin page limited to trusted devices
2. Add local DNS records in Pi-hole pointing each name at the proxy
3. Issue certificates (a Let's Encrypt DNS challenge on a domain you own, or your own internal CA)
4. Never port-forward 80/443: reach it remotely through Tailscale

**Proves:** Practical TLS and certificate handling, and reducing attack surface by putting services behind one hardened entry point.

---

## Master build order (recommended sequence)

```
1. SIEM (Wazuh)              <- do this first, everything else feeds it
2. Windows Server + AD       <- feeds SIEM, unlocks IAM story
3. Kali + vulnerable target  <- feeds SIEM, your best portfolio piece
4. MITRE ATT&CK habit        <- starts the moment Build 3 is live
5. k3s (Kubernetes)          <- independent, $0, do anytime
6. Terraform                 <- independent, $0, do anytime
7. AWS/Azure hybrid project  <- independent, $0 with care
8. OCI free-tier instance    <- independent, $0, high value given your job
9. Packet Tracer recreation  <- independent, can be done in parallel with anything above
10. Proxmox Backup Server    <- do before adding more VMs, so new work is protected
11. Vulnerability scanning    <- after Build 3, scan the lab and the real network
12. Reverse proxy + TLS       <- last, once there are several web UIs to put behind it
```

Builds 5-9 don't depend on each other or on 1-4 — do them in whatever order keeps you motivated. Builds 1-3 are sequential because each feeds the next.

---

## Status tracker

| Build | Status | Certs it closes |
|---|---|---|
| 1. SIEM (Wazuh) | Not started | Security+, CySA+, Cloud+ |
| 2. Windows Server + AD | Not started | Security+, Network+, Oracle |
| 3. Kali + vulnerable target | Not started | Security+ (portfolio) |
| 4. MITRE ATT&CK habit | Not started | Security+, CySA+ |
| 5. k3s (Kubernetes) | Not started | Cloud+ |
| 6. Terraform | Not started | Cloud+ |
| 7. AWS/Azure hybrid | Not started | Cloud+ |
| 8. OCI free-tier | Not started | Oracle |
| 9. Packet Tracer | Not started | Network+, CCNA |
| 10. Proxmox Backup Server | Not started | Cloud+, Security+ (availability) |
| 11. Vulnerability scanning (Greenbone) | Not started | CySA+, Security+ |
| 12. Reverse proxy + internal TLS | Not started | Security+, Network+ |

*(Already complete, not listed above: VLANs and zone firewall, Pi-hole with DNSSEC, Suricata IDS + nftables, Proxmox virtualization, Docker apps, NAS storage, remote access migrated from WireGuard to a Tailscale subnet router, Pi 1 hardening ([write-up](./pi1_hardening.md)), and first-week alert triage ([write-up](./suricata_alert_triage.md)).)*
