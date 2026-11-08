# Incident Report: Servers VLAN Losing DNS After Least-Privilege Firewall Rules

**Date:** 2026-11-08
**Affected systems:** NAS (Servers VLAN — 192.168.20.22), Proxmox host (Servers VLAN — 192.168.20.10), Pi 1 / Pi-hole (Trusted VLAN — 192.168.10.20)
**Severity:** Low (no security impact — the NAS app store and Docker image search were unavailable; running services and data were unaffected)
**Status:** Resolved (2026-11-08)

## Summary

After a NAS firmware update, the NAS App Center showed only its six built-in system apps and Docker's image search returned "No Data." A restart did not help. The NAS still had internet access, but every DNS lookup it made was failing. Three separate problems were stacked on top of each other, and all three had to be fixed before a single lookup would succeed:

1. **No firewall path for DNS.** The Servers VLAN receives Pi-hole (192.168.10.20, Trusted VLAN) as its DNS server from DHCP, but the custom "Servers to Trusted – Block" policy blocks every new connection from Servers to Trusted, including DNS.
2. **Rule order.** The new "Servers to Pi-hole DNS – Allow" policy was listed above the block in the policy table, but UniFi evaluates custom policies by ID, and the block still had the lower ID.
3. **Pi-hole ignoring routed clients.** Pi-hole's listening mode was `LOCAL`, which only answers clients on a directly connected subnet. Queries from 192.168.20.x were silently dropped.

The block rule had been in place since the Trusted/Servers split, so DNS on the Servers VLAN had probably been broken for days. Cached results and an absence of DNS-dependent tasks hid it until the firmware update forced the App Center to refresh its catalog.

## Timeline

| Time | Action | Result |
|---|---|---|
| 11:17 | Noticed App Center listing only 6 system apps, empty category sidebar | Catalog is downloaded from the vendor's servers, so suspected the NAS could not reach them |
| 11:27 | Restarted the NAS after the firmware update | No change — ruled out a stuck service after the update |
| 11:32 | Docker → Image Database | "No Data" — Docker Hub unreachable too, so a network problem rather than an App Center bug |
| 11:33 | Control Panel → Network → LAN1 | DHCP-assigned, gateway 192.168.20.1, **DNS 192.168.10.20** (Pi-hole on the Trusted VLAN) |
| 11:38 | Created "Servers to Pi-hole DNS – Allow" (Servers → 192.168.10.20, TCP/UDP 53, auto return traffic) and placed it above the block in the policy table | No change |
| 11:49 | Pi-hole Query Log, then Diagnosis | Diagnosis badge present; nothing logged from the Servers VLAN |
| 12:02 | From Proxmox (same VLAN): `ping 1.1.1.1`, `nslookup ugreen.com 192.168.10.20`, `nslookup ugreen.com 1.1.1.1` | Ping 0% loss and public DNS answers, but **Pi-hole times out** — internet is fine, only the path to Pi-hole is broken |
| 12:06 | `tcpdump -ni any port 53 and host 192.168.20.10` on Pi 1 while repeating the lookup | **Zero packets** — queries were dropped by the gateway before reaching Pi 1 |
| 12:11 | `ip route get 192.168.10.20` on Proxmox | `via 192.168.20.1 dev vmbr0` — normal LAN path, not through the Tailscale tunnel |
| 12:13 | Paused "Servers to Trusted – Block" and repeated the lookup | Queries now **arrive** at Pi 1 (`In`), but **no reply** goes out — two problems, not one |
| 13:05 | `pihole-FTL --config dns.listeningMode` | `LOCAL`. Set to `ALL` and restarted FTL |
| 16:35 | Re-enabled the block; filtered the Zone Matrix to Internal → Internal | The real evaluation order showed the block at ID 10001 and the allow at **10004**; the block had 252 hits, the most recent minutes earlier |
| 16:38 | Used Reorder to move the allow to the top | Allow is now ID 10000, ahead of the block |
| 16:40 | Repeated the lookup from Proxmox with tcpdump running on Pi 1 | Answer returned (`23.227.38.65`); tcpdump shows the query `In` and the answer `Out` |
| 16:42 | Reopened the NAS App Center | Full catalog (44 apps) loads |

## Root causes

**Cause 1: a block rule with no DNS exception.** "Servers to Trusted – Block" stops servers from starting connections to personal devices, which is the intent. But the Servers VLAN also uses a Trusted-VLAN host (Pi-hole) as its resolver. When the least-privilege rules were designed, the traffic Servers *starts* toward Trusted was not inventoried, so the one required flow, DNS, had no allow.

**Cause 2: the table order is not the evaluation order.** In UniFi's zone-based firewall, custom policies are evaluated by ID. A rule created later gets a higher ID and is evaluated later, regardless of where it appears in the main policy table. The Zone Matrix, filtered to one zone pair, shows the true order and the IDs, and Reorder changes them.

**Cause 3: Pi-hole's default listening mode.** `LOCAL` answers only clients that are one hop away. Every VLAN other than Trusted is routed through the gateway, so their queries were ignored without any error. Changing it to `ALL` is safe here because nothing on the internet can reach port 53: the gateway has zero port forwards, the UniFi policies decide which VLANs reach Pi 1, and the staged host firewall on Pi 1 only allows DNS from 192.168.0.0/16.

## Lessons learned

- **Inventory flows in both directions before writing a block.** "Servers never start connections to Trusted" was almost true. Shared infrastructure (DNS, NTP, syslog) is the usual exception.
- **Check the evaluation order, not the display order.** After adding an allow meant to override a block, confirm the IDs in the zone-pair view. A climbing hit count on the block is the giveaway.
- **Capture on the far end to split the problem.** One `tcpdump` on the DNS server separated "dropped in the network" (no packets), "dropped by the service" (packets in, no reply) and "dropped on the return path" (reply out, client still times out). Pausing the block for one test proved there were two independent faults.
- **Test from a neighbour when the affected host is an appliance.** The NAS has no convenient shell, so Proxmox, on the same VLAN with the same DHCP options, stood in for it.
- **Silent failures need a symptom to surface.** DNS on the Servers VLAN was likely broken from the day the block rule was created. Running services kept working, so nothing alerted until an update needed to reach the internet.

## Follow-up

- [x] Allow Servers → Pi-hole on TCP/UDP 53 only, evaluated before the block.
- [x] Set Pi-hole's listening mode to answer all local VLANs.
- [x] Confirm the NAS App Center and Docker image search load.
- [ ] Move "Trusted to Jellyfin – Allow" from the Internal → External zone pair to Internal → Internal (its destination is on the Servers VLAN), and place it above "Trusted to Servers – Block".
- [ ] Add a DNS check for each VLAN to the uptime monitoring planned for Pi 3, so a silent resolver failure raises an alert.
