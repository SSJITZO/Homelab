# Alert Triage: First Week of Phone Alerts (Oct 31 – Nov 3, 2026)

Two alert feeds push to a phone through ntfy:

| Feed | Source | Signal quality |
|---|---|---|
| IDS feed | Suricata on Pi 2, fed by a switch port mirror | High volume, mostly informational |
| Network feed | UniFi gateway's built-in IPS | Low volume, higher signal |

Within a day of installing Tailscale on the sensor, the IDS feed flooded. Every alert was triaged before deciding what to do with it. None were malicious.

## IDS feed (Suricata)

| Signature | Example flow | Verdict | Why |
|---|---|---|---|
| ET INFO Session Traversal Utilities for NAT (STUN Binding Request / Response) | Sensor ↔ several cloud relay addresses | Benign | Tailscale's NAT traversal. It fires in bursts whenever the node connects or re-connects, matching the times the flood appeared |
| ET INFO Go-http-client User-Agent Observed Outbound | Sensor → a cloud control server | Benign | Tailscale is written in Go; this is its client checking in with the coordination server |
| ET INFO GNU/Linux APT User-Agent Outbound | Sensor → a CDN (Debian mirrors) | Benign | The sensor installing its own package updates |
| ET P2P eMule KAD Network Firewalled Request | Each VLAN's gateway address (.1) → `224.0.0.251` | False positive | `224.0.0.251` is the mDNS multicast group. The gateway repeats mDNS between VLANs so casting and printers work, and the old eMule rule happens to match those bytes. No P2P software is running |

**Pattern:** every alert was `ET INFO` (informational) or a known false positive, and each one traced back to a service deliberately installed on the network.

## Network feed (UniFi IPS)

| Event | Verdict | Notes |
|---|---|---|
| Threat Detected and Blocked (severity 7 and 9) | Handled by the IPS | Blocked inbound internet scanning is routine. The rule of thumb: check the direction. An internal host reaching *out* to a known-bad address would need investigating |
| Multiple Internet Disconnections (severity 10) | Not a security event | WAN instability on 10-07, during the lab's move behind the ISP gateway |
| Test notification / Test Security Event | Ignore | From setting up the pipeline on 09-28 |

## Tuning plan

Narrow suppressions in Suricata's `threshold.config`, each scoped to the known-good traffic so the same signature still fires anywhere else:

```
# STUN and Go-http-client: Tailscale on the sensor itself
suppress gen_id 1, sig_id <STUN request SID>, track by_src, ip 192.168.50.20
suppress gen_id 1, sig_id <STUN response SID>, track by_dst, ip 192.168.50.20
suppress gen_id 1, sig_id <Go-http-client SID>, track by_src, ip 192.168.50.20
# APT: the sensor's own updates
suppress gen_id 1, sig_id <APT SID>, track by_src, ip 192.168.50.20
# eMule KAD: false positive on the gateway's mDNS multicast only
suppress gen_id 1, sig_id <eMule KAD SID>, track by_dst, ip 224.0.0.251
```

The SIDs come from the sensor's `fast.log`. After the change: validate with `suricata -T`, restart, and confirm the noisy alerts stop while a known-good test alert still fires. On the network feed, phone notifications will be limited to severity 8 and above.

**Status:** triage complete; suppressions not yet applied. This page gets updated with the SIDs and before/after alert counts once they are.
