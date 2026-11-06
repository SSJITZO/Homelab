# Homelab Career Pathway Map
### How one project supports four different career tracks

This maps your homelab build to four realistic career paths, with the certifications each one actually requires, in the order the market expects them. Every homelab piece listed under a track is something you've built or planned that directly demonstrates that skill. ✅ = built and verified, 🔲 = planned. Planned items come from the current hardening plan and a set of 15 job-role labs (mapped in full near the end).

---

## Track 1 — Network Engineer

### Career ladder
| Level | Years | Salary Range | Focus |
|---|---|---|---|
| Network Technician / Junior Network Engineer | 0–2 | $55K–$85K | Basic routing, switching, troubleshooting |
| Network Engineer | 2–5 | $75K–$112K | Network design, security, protocols |
| Senior Network Engineer | 5–10 | $105K–$145K | Architecture, automation, multi-site |
| Principal Network Architect | 10+ | $140K–$220K+ | Enterprise strategy, SD-WAN, cloud integration |

### Certification path (in order)
1. **CompTIA Network+ (N10-009)** — foundation, vendor-neutral. *2–4 months.*
2. **Cisco CCNA (200-301)** — the real entry ticket for most network engineer job postings. *3–6 months.*
3. **CompTIA Security+** — increasingly required alongside networking certs; many postings now list it as a minimum. *2–3 months.*
4. **Cisco CCNP Enterprise** (Core exam ENCOR + 1 concentration exam) — the mid-level jump, correlates with a real salary bump. *6–12 months.*
5. *(Specialize)* **CCNP Security** (network security focus) or **CCNP Automation** (network programmability/Python) — pick based on interest.
6. **CCIE Enterprise Infrastructure** — expert level, 12–24 months, only pursue once you need to prove lab-tested mastery.

### What your homelab already proves for this track
- ✅ Real VLAN design and segmentation (6 VLANs, zone-based firewall) — UniFi
- ✅ Firewall rule construction and troubleshooting — UniFi zone matrix
- ✅ NAT and double-NAT diagnosis — solved it live with AT&T BGW320 passthrough and again with the Xfinity XB8-T bridge mode
- ✅ DHCP, DNS, and static reservations — throughout
- ✅ Real network troubleshooting under pressure — the 1G bottleneck, VLAN reachability issues, WireGuard handshake debugging, and a Tailscale subnet-route problem traced to a stateless firewall rule dropping replies ([incident report](../incident-reports/2026-11-05-tailscale-subnet-route-conflict.md))
- ✅ Cabling/media decisions — Cat6a vs SFP+ DAC, PoE budgets
- 🔲 **Gap: Cisco IOS CLI syntax.** UniFi's GUI doesn't teach this. **Fix: recreate your topology in Cisco Packet Tracer** (already planned) — this is what actually closes the CCNA/CCNP gap.
- 🔲 **Gap: dynamic routing protocols** (OSPF, EIGRP). Not present in a single-gateway home network — study this separately, Packet Tracer can simulate it.
- 🔲 **Least-privilege segmentation.** Replace the broad Trusted → Servers allow with per-device rules (subnet router and admin devices only), move Management into its own zone, and send unused switch ports to a blackhole VLAN.
- 🔲 **Edge hardening.** UPnP off, IPS set to block, WPA3 plus separate IoT and Guest SSIDs with client isolation, firmware and config backups on a schedule.
- 🔲 **DNS redundancy and internal names.** A second Pi-hole as backup DNS, plus a reverse proxy with `home.arpa` names and internal TLS for every web UI.
- 🔲 **Lab 06 — Security Architect:** zero-trust segmentation and a STRIDE threat model, compared against the real VLAN and zone design.
- 🔲 **Lab 07 — Network Security Engineer:** custom Suricata rules validated with `suricata -T`, loaded on the real sensor, and triaged from `eve.json`.

---

## Track 2 — Cloud Engineer

### Career ladder
| Level | Years | Salary Range | Scope |
|---|---|---|---|
| Junior Cloud Engineer / Cloud Support | 0–2 | $90K–$120K | Individual tasks, runbooks, troubleshooting |
| Cloud Engineer | 2–5 | $115K–$145K | Owns services end-to-end |
| Senior Cloud Engineer | 5–8 | $140K–$180K | Architecture for a domain |
| Staff / Principal Cloud Architect | 8–12+ | $170K–$260K+ | Org-wide cloud strategy |

### Certification path (in order)
1. **CompTIA Cloud+ (CV0-004)** — vendor-neutral foundation covering virtualization, containers, IaC, security. *2–3 months.*
2. **AZ-900 (Azure Fundamentals)** or **AWS Cloud Practitioner** — cheap, fast, proves direction. *2–4 weeks.* (Pick Azure if targeting enterprise/Microsoft-shop employers like Oracle-adjacent corporate IT; pick AWS for broadest market recognition — AWS holds ~31% cloud market share.)
3. **AZ-104 (Azure Administrator)** or **AWS Solutions Architect – Associate (SAA-C04)** — your first real, job-qualifying cloud cert. *8–12 weeks.*
4. **HashiCorp Terraform Associate** — Infrastructure as Code, increasingly expected alongside any cloud associate cert.
5. *(Specialize)* **AZ-305 (Azure Solutions Architect Expert)** or **AWS Solutions Architect – Professional** — the senior-level cert, correlates with a 20–30% salary bump.
6. *(Optional specialty)* **CKA (Certified Kubernetes Administrator)** if targeting container-platform-heavy roles. **AWS/Azure Security Specialty** if leaning security.

### What your homelab already proves for this track
- ✅ **Virtualization (Proxmox)** — this is huge; Cloud+'s Architecture & Deployment domain is 42% of the exam, and hands-on hypervisor experience is exactly what it tests
- ✅ Storage integration (NAS via SMB/CIFS into Proxmox)
- ✅ Docker containerization (Jellyfin, Jellyseerr, qBittorrent, planned Nextcloud/Immich)
- 🔲 **Gap: Kubernetes.** Add **k3s** (lightweight Kubernetes) on Pi 3/Pi 4 or as Proxmox VMs — $0 cost, uses hardware you already own.
- 🔲 **Gap: Infrastructure as Code.** Add **Terraform** managing at least one Proxmox VM via its Proxmox provider — replaces manual GUI clicks with code.
- 🔲 **Backup and recovery.** Proxmox Backup Server on a second node, encrypted nightly backups to the NAS, weekly verify jobs and monthly test restores, plus an offsite copy (3-2-1).
- 🔲 **A second Proxmox node.** A Lenovo M720q (i7-8700T, 32 GB) to host the backup server and scanner, and to practise clustering.
- 🔲 **Lab 02 — Cloud Security Engineer:** scanning insecure vs. secure Terraform with Checkov, tracing each finding to its fix, with a stretch goal of porting one resource to OCI.
- 🔲 **Lab 03 — DevSecOps Engineer:** SAST (Bandit) and dependency scanning (pip-audit) on a deliberately vulnerable app, a hardened non-root container, and a CI pipeline running the same checks.
- 🔲 **A local AI node.** A GMKtec EVO-X2 (Ryzen AI Max+ 395, 64 GB) running models on-prem for automation workflows, joined to the lab like any other server.
- 🔲 **Gap: actual public cloud.** No amount of homelab work substitutes for touching a real cloud console. **Fix: free-tier AWS or Azure account**, build one small hybrid project (e.g., a cloud VM joined to your tailnet, or a WireGuard site-to-site tunnel, linking your homelab to the cloud). This single project closes the "hybrid cloud" objective directly.

---

## Track 3 — Security Analyst / SOC Analyst

### Career ladder
| Level | Years | Salary Range | Focus |
|---|---|---|---|
| SOC Analyst (Tier 1) | 0–2 | $50K–$85K | Alert triage, SIEM monitoring |
| Security Analyst (Tier 2) / Junior Security Engineer | 2–4 | $75K–$110K | Investigation, threat hunting |
| Senior Security Analyst / Engineer | 4–8 | $107K–$150K | Incident response, detection engineering |
| Security Architect / Manager | 8–15+ | $130K–$220K+ | Strategy, governance, leadership |

### Certification path (in order)
1. **CompTIA Security+ (SY0-701)** — the standard entry credential, required for many roles and DoD-approved positions. *2–3 months.*
2. **CompTIA CySA+ (CS0-003)** — the direct SOC analyst / threat-detection credential, natural next step. *3–4 months.*
3. *(Choose one path)*
   - **Blue team / detection track:** stay on CySA+, add **GCIA** (network intrusion analysis) if network-heavy environments interest you
   - **Red team / offensive track:** **PenTest+** or **CEH**, then **OSCP** for serious hands-on credibility
4. **Cloud security cert** — **AWS Security Specialty** or **Azure AZ-500** — cloud security is now table-stakes for mid-level roles
   - *(Emerging specialty)* **CompTIA SecAI+ (CY0-001)** — AI security, launched February 2026; recommended after Security+ or CySA+. Domains: basic AI concepts (17%), securing AI systems (40%), AI-assisted security (24%), and AI governance, risk and compliance (19%).
5. *(Senior/management track)* **CISSP** (5 years experience required) or **CISM** for leadership; **CCSP** if specializing in cloud security specifically

### What your homelab already proves for this track
- ✅ **Suricata IDS** — installed, configured, and verified with a real test-alert detection on Pi 2
- ✅ **nftables firewall** — hands-on packet filtering, verified not to lock yourself out
- ✅ **VLAN-based network segmentation** — a real defense-in-depth control
- ✅ **Defense-in-depth, layered firewalls** — UniFi zone rules + per-device host firewalls (nftables, Proxmox FW, UGOS; ufw staged on Pi 1)
- ✅ **Host hardening with verified controls** — key-only SSH, fail2ban, automatic security patching and DNSSEC on the DNS server, each proven with a test ([write-up](./pi1_hardening.md))
- ✅ **Alert triage and tuning** — a week of real IDS and IPS alerts classified as benign or false positive, with a scoped suppression plan ([write-up](./suricata_alert_triage.md))
- 🔲 **Gap: SIEM experience.** *(Already planned)* Deploy **Wazuh** or **Security Onion** as a Proxmox VM, ship Suricata + Pi-hole + endpoint logs into it. This is the single highest-value addition — nearly every SOC job posting names a SIEM by tool.
- 🔲 **Gap: Active Directory / identity.** *(Already planned)* Windows Server + AD VM on Proxmox — teaches IAM, the backbone of most enterprise security work.
- 🔲 **Gap: an actual attack you detected and investigated.** *(Already planned)* Kali + vulnerable target VMs — the attack→detect→triage→document loop is your single strongest portfolio piece across ALL cybersecurity interviews.
- 🔲 **Gap: MITRE ATT&CK mapping.** When Suricata/SIEM catches something, document *which ATT&CK technique* it represents — this is a specific, checkable skill recruiters look for.
- 🔲 **Vulnerability management.** Greenbone/OpenVAS scans of every VLAN (unauthenticated, then authenticated), findings ranked by severity, fixed and rescanned, with before/after reports.
- 🔲 **Finish hardening every host.** Enable the staged ufw policy on Pi 1; give the IDS sensor the same baseline (key-only SSH, fail2ban, patching, DNS pinning) and apply its scoped Suricata suppressions; Proxmox 2FA, key-only SSH and its firewall; NAS admin lockdown, SMB2/3 only and immutable snapshots.
- 🔲 **Identity hardening.** Phishing-resistant MFA with two hardware security keys on GitHub, the Tailscale identity provider, UniFi and Proxmox; Tailscale device approval, least-privilege access rules and Tailnet Lock.
- 🔲 **Deception.** An internal honeypot (OpenCanary) on its own Pi: nothing legitimate ever connects to it, so any connection is an early warning of scanning or lateral movement.
- 🔲 **Job-role labs for this track:**
  - **Lab 01 — Security Engineer:** SSH brute-force and password-spraying detection, then hardening that is checked against the live Pi baseline.
  - **Lab 04 — Threat Hunter:** Sigma 2.0 detection rules and a hunt across sample telemetry, each finding mapped to MITRE ATT&CK, then one detection rebuilt in Wazuh.
  - **Lab 05 — Incident Responder:** a NIST SP 800-61 playbook walked as a tabletop, a merged attack timeline, and a written postmortem.
  - **Lab 08 — IAM Engineer:** an access review that flags missing MFA, conflicting roles and excess privilege, repeated for real on every homelab account.
  - **Lab 09 — Security Manager:** a scored risk register and a remediation roadmap, rebuilt with the homelab's real risks.
  - **Lab 10 — GRC Analyst:** a NIST CSF 2.0 assessment across Govern, Identify, Protect, Detect, Respond and Recover, with a gap analysis.
- 🔲 **AI security labs (SecAI+):**
  - **Lab 11 — AI basics and data security:** local models, an AI asset inventory, and secret scanning before any data reaches a model.
  - **Lab 12 — AI-assisted alert triage:** a local model labelling real Suricata alerts, scored against known-benign traffic, with a human always checking the output.
  - **Lab 13 — Securing an AI app:** a small chatbot threat-modelled against the OWASP Top 10 for LLM Applications and MITRE ATLAS, scanned with garak, hardened (output filtering, rate limits, least privilege) and monitored by a Wazuh rule that fires if protected data leaks.
  - **Lab 14 — AI governance:** an AI acceptable-use policy, AI risks added to the risk register, a NIST AI RMF mapping and a model card.
  - **Lab 15 — AI security tools:** AI code review compared with Bandit on a known-vulnerable app, written up as a buyer's comparison.

---

## Track 4 — Oracle (your current employer, Service Desk Analyst)

This is the most personally relevant one — your homelab work directly supports internal promotion, and Oracle Cloud Infrastructure (OCI) certifications are a distinct, valuable, and underused credential path since you already have the employer relationship.

### Oracle's internal career ladder (from where you are now)
| Level | Typical next step from Service Desk Analyst |
|---|---|
| **Current: Service Desk Analyst (Tier 1)** | Ticket triage, incident logging, basic troubleshooting, escalation |
| **Senior Service Desk Analyst** | Leads complex tickets, mentors junior analysts, contributes to KB/runbooks |
| **Lateral options at this stage** | EUC/Desktop Support Engineer · IAM Analyst (junior) · Application Support Analyst · ITSM/Process Analyst |
| **Technical specialization tracks** | Network team (escalation path for VPN/WiFi/DNS/routing) · Cloud/Infrastructure/SRE (platform outages) · Security/SecOps/GRC (phishing, access governance) |
| **Target: OCI-focused infrastructure role** | Specialist, Infrastructure Operations (OCI) — real Oracle job postings ask for Linux server admin background, OCI compute/storage/networking/IAM knowledge |

**The realistic internal path for you:** Service Desk Analyst → Senior Service Desk Analyst → lateral move into Cloud/Infrastructure or IAM Analyst (your homelab directly supports both) → OCI Infrastructure Specialist.

### Oracle-specific certifications worth pursuing
1. **Oracle Cloud Infrastructure (OCI) Foundations Associate** — free, fast, proves basic OCI literacy. Do this first; it's low-effort and directly relevant to your employer.
2. **OCI Certified Architect Associate** — the real credential for infrastructure/architecture roles inside Oracle or with Oracle customers.
3. **OCI Certified Architect Professional** — senior-level, pairs well with AWS/Azure certs since most enterprises run multi-cloud including OCI.
4. *(If DBA-curious)* **Oracle Certified Professional (OCP), Oracle Database** — a completely different but very in-demand Oracle-specific track if you ever want to pivot toward database administration, which Oracle itself hires heavily for.

### Why this track matters strategically
Oracle actively hires internally for Infrastructure Operations roles requiring OCI knowledge, Linux server administration, and networking — all things your homelab already builds. Because you already work at Oracle, an **OCI certification is disproportionately valuable to you specifically** compared to an outside candidate — it signals both technical readiness and internal commitment, and Oracle's internal mobility tools (Oracle Grow) let you formally track and pursue defined career progression paths within the company.

### What your homelab already proves for this track
- ✅ Everything from the Network Engineer and Cloud tracks above — internal Oracle infrastructure roles want exactly this blend
- ✅ Linux server administration (all four Pis, Proxmox host)
- ✅ IAM fundamentals *(once the Windows AD VM is built)* — directly maps to the "IAM Analyst" lateral option
- 🔲 **Lab 08 (IAM access review)** — the day-to-day work of an IAM Analyst: who has access, whether they still need it, and whether MFA is on
- 🔲 **Lab 02's OCI stretch goal** — the same misconfiguration scanning applied to an OCI resource, a direct bridge to OCI Architect Associate
- 🔲 **Gap: OCI-specific hands-on time.** OCI has an **Always Free tier** (similar structure to AWS/Azure) — spin up a free OCI compute instance and mirror one of your homelab services there (e.g., a small web app, or a node on your tailnet) to get genuine OCI console experience for $0.

---

## Master cert overlap — buy once, use everywhere

Some certifications count toward multiple tracks simultaneously. Prioritize these first for maximum efficiency:

| Certification | Network+ track | Cloud track | Security track | Oracle track |
|---|---|---|---|---|
| **CompTIA Network+** | ✅ Core | — | Foundation | Helpful |
| **CompTIA Security+** | ✅ Required by many postings | Security domain | ✅ Core | Helpful (IAM-adjacent roles) |
| **CompTIA Cloud+** | — | ✅ Core | Security domain overlap | Directly relevant (OCI concepts transfer) |
| **Terraform Associate** | — | ✅ Core (IaC) | — | Useful (Oracle uses IaC too) |
| **AZ-900 / AWS Cloud Practitioner** | — | ✅ Entry point | — | Conceptually transfers to OCI |
| **OCI Foundations Associate** | — | Transfers | — | ✅ Core, and free |

**Recommended overall order given everything above:** Network+ → Security+ → Cloud+ → (CCNA if going deep on networking) → CySA+ or AZ-104/SAA-C04 depending on which track pulls you more → OCI Foundations (cheap add-on, high value at your current job) → specialize from there based on which track excites you most in practice.

---

## Job-role labs at a glance

Fifteen hands-on labs, each built around one real job. Labs 01–10 follow a single SSH-compromise story end to end; labs 11–15 cover AI security for SecAI+. All are planned; each will get a short write-up as it is completed.

| Lab | Job it practices | Track(s) | Certs it supports |
|---|---|---|---|
| 01 SSH detection and hardening | Security Engineer | Security | Security+, CySA+ |
| 02 Terraform misconfiguration scan | Cloud Security Engineer | Cloud, Oracle | Cloud+, Terraform Associate, OCI |
| 03 DevSecOps pipeline | DevSecOps Engineer | Cloud, Security | Cloud+, Security+ |
| 04 Threat hunting | Threat Hunter | Security | CySA+ |
| 05 Incident response | Incident Responder | Security | CySA+, Security+ |
| 06 Security architecture | Security Architect | Network, Security | Security+, Network+ |
| 07 Network security | Network Security Engineer | Network, Security | Network+, CySA+ |
| 08 IAM access review | IAM Engineer | Security, Oracle | Security+ |
| 09 Risk register and roadmap | Security Manager | Security | Security+, CISSP (later) |
| 10 NIST CSF assessment | GRC Analyst | Security | Security+, CISSP (later) |
| 11 AI basics and data security | AI Security | Security | SecAI+ |
| 12 AI-assisted alert triage | SOC Analyst | Security | SecAI+, CySA+ |
| 13 Securing an AI app | AI Security Engineer | Security | SecAI+ |
| 14 AI governance, risk and compliance | GRC Analyst | Security | SecAI+ |
| 15 AI security tools compared | Security Manager | Security | SecAI+ |

---

## Suggested homelab build order to close every remaining gap

1. **Finish hardening** — Pi 1 firewall, the IDS sensor, Proxmox, NAS, UniFi and Tailscale least privilege
2. **Proxmox Backup Server** on a second node — protects everything built after it
3. **SIEM** (Wazuh) on Proxmox — closes the biggest Security+ / CySA+ gap
4. **Windows Server + Active Directory VM** — closes the Security+ IAM gap AND supports the Oracle IAM Analyst lateral path
5. **Kali + vulnerable target VMs** — the attack→detect→document portfolio centerpiece
6. **Vulnerability scanning** (Greenbone) — scan, fix, rescan, report
7. **Reverse proxy + internal TLS** — clean names and HTTPS for every web UI
8. **Backup DNS and an internal honeypot** — resilience and early warning
9. **k3s (Kubernetes)** — closes the Cloud+ containerization gap, $0 cost
10. **Terraform** managing a Proxmox VM — closes the Cloud+ IaC gap, $0 cost
11. **One AWS/Azure free-tier hybrid project** — closes the Cloud+ public-cloud gap
12. **One OCI free-tier instance** — Oracle-specific, high leverage given your current employer
13. **Cisco Packet Tracer recreation** of your topology — closes the Network Engineer CLI/CCNA gap
14. **Local AI node** — hosts the AI security labs and day-to-day automation

The job-role labs run alongside the builds: labs 01, 03 and 06 need only a lab VM, lab 07 uses the existing sensor, lab 04 finishes once the SIEM is up, and labs 11–15 run on a local model.

Most of these are free or near-free and build on hardware or software already running; the second Proxmox node and the AI node are the planned hardware purchases.
