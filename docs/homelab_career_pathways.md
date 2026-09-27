# Homelab Career Pathway Map
### How one project supports four different career tracks

This maps your homelab build to four realistic career paths, with the certifications each one actually requires, in the order the market expects them. Every homelab piece listed under a track is something you've built or planned that directly demonstrates that skill.

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
- ✅ Real network troubleshooting under pressure — the 1G bottleneck, VLAN reachability issues, WireGuard handshake debugging
- ✅ Cabling/media decisions — Cat6a vs SFP+ DAC, PoE budgets
- 🔲 **Gap: Cisco IOS CLI syntax.** UniFi's GUI doesn't teach this. **Fix: recreate your topology in Cisco Packet Tracer** (already planned) — this is what actually closes the CCNA/CCNP gap.
- 🔲 **Gap: dynamic routing protocols** (OSPF, EIGRP). Not present in a single-gateway home network — study this separately, Packet Tracer can simulate it.

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
- 🔲 **Gap: actual public cloud.** No amount of homelab work substitutes for touching a real cloud console. **Fix: free-tier AWS or Azure account**, build one small hybrid project (e.g., WireGuard site-to-site linking your homelab to a cloud VM). This single project closes the "hybrid cloud" objective directly.

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
5. *(Senior/management track)* **CISSP** (5 years experience required) or **CISM** for leadership; **CCSP** if specializing in cloud security specifically

### What your homelab already proves for this track
- ✅ **Suricata IDS** — installed, configured, and verified with a real test-alert detection on Pi 2
- ✅ **nftables firewall** — hands-on packet filtering, verified not to lock yourself out
- ✅ **VLAN-based network segmentation** — a real defense-in-depth control
- ✅ **Defense-in-depth, layered firewalls** — UniFi zone rules + per-device host firewalls (ufw, nftables, Proxmox FW, UGOS)
- 🔲 **Gap: SIEM experience.** *(Already planned)* Deploy **Wazuh** or **Security Onion** as a Proxmox VM, ship Suricata + Pi-hole + endpoint logs into it. This is the single highest-value addition — nearly every SOC job posting names a SIEM by tool.
- 🔲 **Gap: Active Directory / identity.** *(Already planned)* Windows Server + AD VM on Proxmox — teaches IAM, the backbone of most enterprise security work.
- 🔲 **Gap: an actual attack you detected and investigated.** *(Already planned)* Kali + vulnerable target VMs — the attack→detect→triage→document loop is your single strongest portfolio piece across ALL cybersecurity interviews.
- 🔲 **Gap: MITRE ATT&CK mapping.** When Suricata/SIEM catches something, document *which ATT&CK technique* it represents — this is a specific, checkable skill recruiters look for.

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
- 🔲 **Gap: OCI-specific hands-on time.** OCI has an **Always Free tier** (similar structure to AWS/Azure) — spin up a free OCI compute instance and mirror one of your homelab services there (e.g., a small web app or a second WireGuard endpoint) to get genuine OCI console experience for $0.

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

## Suggested homelab build order to close every remaining gap

1. **SIEM** (Wazuh or Security Onion) on Proxmox — closes the biggest Security+ / CySA+ gap
2. **Windows Server + Active Directory VM** — closes Security+ IAM gap AND supports the Oracle IAM Analyst lateral path
3. **Kali + vulnerable target VMs** — the attack→detect→document portfolio centerpiece
4. **k3s (Kubernetes)** on existing Pi hardware — closes the Cloud+ containerization gap, $0 cost
5. **Terraform** managing a Proxmox VM — closes the Cloud+ IaC gap, $0 cost
6. **One AWS/Azure free-tier hybrid project** — closes the Cloud+ public-cloud gap
7. **One OCI free-tier instance** — Oracle-specific, high leverage given your current employer
8. **Cisco Packet Tracer recreation** of your topology — closes the Network Engineer CLI/CCNA gap

Every one of these is free or near-free, and every one builds on hardware or software you already have running.
