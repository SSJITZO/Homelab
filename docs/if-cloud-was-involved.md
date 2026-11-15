# If Cloud Was Involved

This homelab runs on hardware at home. This page shows how I would design each part of it in **AWS** and **Azure**, why, and what it would cost. It also covers the cloud labs I have completed that back up those designs.

It is a design document, not a description of running cloud infrastructure. I chose not to keep cloud resources up full time while I study. The [cost section](#what-it-would-cost) explains that decision.

---

## The homelab, translated

| Homelab component | AWS design | Azure design | Design note |
|---|---|---|---|
| **Six VLANs** (Management, Trusted, Servers, IoT, Guest, Lab) | One VPC; one subnet per tier, across two Availability Zones | One VNet; one subnet per tier | A VLAN maps to a subnet. Address ranges are planned so on-prem and cloud never overlap (on-prem 192.168.0.0/16, AWS 10.50.0.0/16, Azure 10.60.0.0/16) |
| **UniFi zone-based firewall**, rules evaluated by ID | Security groups (stateful, per instance) plus network ACLs (stateless, numbered rules, lowest first) | Network security groups (stateful, priority numbers, lowest first) on subnets or NICs | Same lesson in all three: [evaluation order is not display order](../incident-reports/2026-11-08-servers-vlan-dns-failure.md). A NACL with no return rule drops replies, the same failure as [a block rule without connection state](../incident-reports/2026-11-05-tailscale-subnet-route-conflict.md) |
| **Zero port forwards** on the gateway | No public IPs on servers; admin through **SSM Session Manager**; internet gateway only for public-facing tiers | No public IPs; admin through **Microsoft Entra login** or a private path; Azure Bastion only where justified | Nothing listens on the internet unless it has to. Same rule as at home |
| **Tailscale subnet router** (Pi 1) for remote access | **Site-to-Site VPN** (customer gateway, virtual private gateway, two IPsec tunnels); **Transit Gateway** if there are many VPCs | **VPN Gateway** (site-to-site, point-to-site); **Virtual WAN** at scale | I built the AWS side in a lab (below). For a homelab, an overlay like Tailscale does the same job for free; a business with an SLA would choose IPsec or Direct Connect / ExpressRoute |
| **Pi-hole DNS** for every VLAN | **Route 53 Resolver**, with **DNS Firewall** for blocklists; resolver endpoints for hybrid lookups | **Azure DNS Private Resolver**, or Azure Firewall DNS proxy | The [Nov 8 incident](../incident-reports/2026-11-08-servers-vlan-dns-failure.md) is why DNS gets designed first: every subnet needs a path to the resolver |
| **Suricata IDS** on a switch mirror port | **VPC Traffic Mirroring** to a Suricata instance; or **AWS Network Firewall**, which accepts Suricata-compatible rules; **GuardDuty** for managed detection | **Azure Firewall Premium** (IDPS); **Microsoft Defender for Cloud**; packet capture with Network Watcher | My [suppression tuning](./suricata_alert_triage.md) carries over directly to Network Firewall rule groups |
| **ntfy alert pipeline** (Suricata and UniFi to my phone) | **EventBridge** or **CloudWatch alarm** → **SNS** → email or SMS | **Azure Monitor alert** → **action group** | Same pattern: detect, filter by severity, notify. Only severe alerts page a human |
| **Health checks** (`healthcheck.sh`, every 5 min, alert after 2 failures, recovery notice) | **Route 53 health checks** or **CloudWatch Synthetics** canaries + alarms | **Application Insights availability tests** + alerts | The two-failure threshold is the same idea as an alarm's "datapoints to alarm" setting |
| **Monthly maintenance** (upgrade, reboot only if needed, verify after boot) | **Systems Manager Patch Manager** with a **maintenance window** | **Azure Update Manager** with a maintenance configuration | Patch window, fail-safe on errors, post-patch verification: the same three steps, managed |
| **Ansible** (idempotent playbooks, per-host vars) | Ansible as-is; **SSM State Manager** for drift; **AWS Config** to detect non-compliant resources | Ansible as-is; **Azure Machine Configuration** and **Azure Policy** | Configuration as code works the same on a Pi or a cloud VM |
| **Host hardening** (key-only SSH, fail2ban, ufw, automatic security updates) | Session Manager instead of SSH, security groups, **Amazon Inspector** for vulnerabilities | Entra login for Linux VMs, NSGs, Defender for Cloud | Remove the attack surface first (no SSH from the internet), then harden what remains |
| **Proxmox VMs** | EC2 instances from a launch template, in an **Auto Scaling group** for anything that must stay up | Azure VMs; **Virtual Machine Scale Sets** | Built and tested in the EC2 Auto Scaling lab (below) |
| **NAS + Jellyfin** | Media in S3, Jellyfin on EC2 or ECS | Blob storage + Container Apps | **I would keep this on-prem**: streaming video out of a cloud means data transfer charges on every play |
| **Config backups** (Pi-hole Teleporter, Suricata config) | S3 with versioning, default encryption, lifecycle rules and a least-privilege write-only IAM user | Blob container with versioning, soft delete, lifecycle management and a container-scoped SAS or RBAC role | This is what I would move first: an off-site copy satisfies the 3-2-1 backup rule for a few cents a month |
| **Identity**: Tailscale access rules, SSH keys, MFA | **IAM Identity Center** with MFA; IAM groups; root account locked away | **Microsoft Entra ID** with Conditional Access; **Azure RBAC** at the narrowest scope | Least privilege, tested rather than assumed (see the Azure RBAC lab) |

---

## Cloud labs completed

| Lab | What I built | What I proved | Where it shows up in the homelab |
|---|---|---|---|
| **EC2 launch template + Auto Scaling** (AWS) | Key pair, security group, launch template, Auto Scaling group across two Availability Zones, Application Load Balancer and target group | **Self-healing:** I terminated an instance and the Auto Scaling group launched a replacement with no manual steps | The same goal as my monthly maintenance boot check: services come back by themselves |
| **Public and private VPC** (AWS) | Internet gateway, NAT gateway, separate public and private route tables | Private instances reach the internet outbound but cannot be reached inbound; noted that a NAT gateway belongs in a public subnet | My VLAN design: Lab and IoT networks can get out but nothing gets in |
| **Site-to-Site VPN** (AWS) | VPC, customer gateway, virtual private gateway, VPN connection with static routing, route propagation, cleanup in dependency order | Understood why both tunnels show "down" with no physical on-prem device, and why the on-prem range must not overlap the VPC | The cloud version of my Tailscale subnet router |
| **S3 static website** (AWS) | Two buckets, versioning, server access logging to a private log bucket, bucket policy, static website hosting | Restored a deleted object by removing its delete marker; kept logs private because they contain visitor IPs | Backup design: versioning plus lifecycle rules for config backups |
| **Azure RBAC and custom roles** (Azure) | Built-in **Network Contributor** role assigned at resource-group scope; custom role created with PowerShell (`New-AzRoleDefinition`) | **Least privilege, tested:** the user could create a VNet but was denied creating a storage account | The same "smallest scope that works" rule as my firewall and Tailscale access rules |
| **AWS account baseline** (personal account, 2026) | Admin group with only `AdministratorAccess`, an everyday IAM admin user, root reserved for billing and emergencies | Group-based permissions instead of per-user policies | The account is ready for future hands-on labs |

---

## What it would cost

Prices are approximate US list prices as of November 2026.

| Item | Monthly | Yearly | Decision |
|---|---|---|---|
| VPC or VNet, subnets, route tables, security groups | $0 | $0 | Free; can stay up permanently |
| One small Linux VM (t3.micro or B1s) running 24/7 | about $7.60 | about $91 | Only when it has a job; otherwise start and stop it per lab |
| Public IPv4 address | about $3.65 | about $44 | The cost most people miss |
| **NAT gateway** | about $32 + data | $384+ | **Avoided.** A lab does not need one; IPv6 egress or an overlay network covers outbound access |
| **Site-to-Site VPN** | about $36 | about $438 | **Avoided** for the homelab; Tailscale provides the same connectivity |
| Off-site config backups (S3 or Blob) | under $0.10 | about $1 | Worth it |

**Lab mode:** keeping networks up, starting VMs only while working and using auto-shutdown keeps both clouds at about **$1–3 a month**.

---

## What I would move, and what I would keep

| Move to cloud | Keep on-prem |
|---|---|
| Off-site backups (cheap, big resilience gain) | Media streaming (data transfer costs) |
| An external monitoring point that checks the homelab from outside | The IDS (it needs to see local traffic) |
| Disposable lab VMs for testing changes before they reach the Pis | DNS for local devices (it must work when the internet is down) |

---

## Lessons that carry across

1. **Rule order is the evaluation order, not the display order.** UniFi custom rules run by ID, NACLs by rule number and NSGs by priority. I learned it the hard way [on Nov 8](../incident-reports/2026-11-08-servers-vlan-dns-failure.md).
2. **Stateful vs stateless.** A UniFi block rule without connection state broke replies [on Nov 5](../incident-reports/2026-11-05-tailscale-subnet-route-conflict.md). A stateless NACL behaves the same way without a return rule.
3. **DNS is shared infrastructure.** Every network segment needs a path to the resolver, on-prem or in a VPC.
4. **Test least privilege; don't assume it.** The Azure RBAC lab proved a denial, and my firewall checks prove blocked paths, the same way.
5. **Cost is a design input.** Two managed services (a NAT gateway and a VPN connection) would cost more each year than all the hardware upgrades on my list.

---

*Related: [roadmap](./gap_closure_roadmap.md) · [Pi 1 hardening](./pi1_hardening.md) · [Suricata alert triage](./suricata_alert_triage.md)*
