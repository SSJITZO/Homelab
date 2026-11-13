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

## Tuning applied (2026-11-11)

Alert counts in `fast.log` before tuning, with each signature traced to its source:

| Count | SID | Signature | Flow | Verdict |
|---|---|---|---|---|
| 2,338 | 2016149 | ET INFO STUN Binding Request | Sensor → relay servers | VPN client NAT traversal |
| 283 | 2016150 | ET INFO STUN Binding Response | Relay servers → sensor | VPN client NAT traversal |
| 52 | 2013504 | ET INFO GNU/Linux APT User-Agent Outbound | Sensor → Debian mirrors | The sensor's own updates |
| 29 | 2027397 | ET INFO Spotify P2P Client | A Management VLAN client → its broadcast address | Speaker discovery from a family device |
| 14 | 2071656 | ET INFO Tailscale DERP Relay Server in TLS SNI | Sensor → relay | VPN client |
| 8 | 2019102 | ET DOS Possible SSDP Amplification Scan in Progress | Sensor → its own gateway, UDP 1900 | The VPN client probing the gateway for UPnP port mapping |
| 5 | 2060251 | ET INFO Go-http-client User-Agent Observed Outbound | Sensor → control server | VPN client |
| 5 | 2024897 | ET USER_AGENTS Go HTTP Client User-Agent | Sensor → control server | VPN client |
| 4 | 2071648 | ET INFO Tailscale Control Plane in TLS SNI | Sensor → control server | VPN client |

Two of these were worth more than a glance:

- **The "SSDP amplification scan"** has an alarming name, so its direction was checked before touching it. Source and destination were both internal (the sensor to its own gateway), which is a device asking its router about port mapping, not an inbound scan. A public source address would have been investigated instead.
- **The Spotify broadcast** came from a client on a different VLAN than the sensor. That confirms the port mirror is delivering traffic from other networks, not only the sensor's own.

Suppressions in `/etc/suricata/threshold.config`, each scoped to the known-good host so the same signature still fires for any other device:

```
# VPN client on the sensor itself (STUN, relay, control plane, Go client)
suppress gen_id 1, sig_id 2016149, track by_src, ip 192.168.50.20
suppress gen_id 1, sig_id 2016150, track by_dst, ip 192.168.50.20
suppress gen_id 1, sig_id 2071656, track by_src, ip 192.168.50.20
suppress gen_id 1, sig_id 2071648, track by_src, ip 192.168.50.20
suppress gen_id 1, sig_id 2060251, track by_src, ip 192.168.50.20
suppress gen_id 1, sig_id 2024897, track by_src, ip 192.168.50.20
# The sensor's own package updates
suppress gen_id 1, sig_id 2013504, track by_src, ip 192.168.50.20
# The VPN client's port-mapping probe to the gateway
suppress gen_id 1, sig_id 2019102, track by_src, ip 192.168.50.20
# Speaker discovery broadcasts
suppress gen_id 1, sig_id 2027397
```

### Verification

| Check | Result |
|---|---|
| `suricata -T -c /etc/suricata/suricata.yaml` | Configuration loaded successfully |
| `suricata.log` after restart | `Threshold config parsed: 9 rule(s) found` |
| `curl -A "BlackSun" http://testmyids.com` | SID 2008983 (suspicious user agent) and SID 2100498 (`id` check returned root) both logged |
| `fast.log` after the restart | Only the two test alerts; none of the nine suppressed signatures |

A real detection still fires, and roughly 2,700 informational alerts no longer do.

### A second finding: the alert forwarder was the bottleneck

The test alert reached `fast.log` but not the phone. The forwarding service was still running, and its process list showed it sending a STUN alert from hours earlier: it was working through a backlog. The original script handled one log line at a time, started four `jq` processes per line (for every event type, not just alerts), and sent each alert with no timeout, so a slow send stalled everything behind it. It had used over 2.5 hours of CPU time.

Rewritten as a single streaming filter that forwards only priority 1 and 2 alerts, with a time limit on each send:

```bash
#!/bin/bash
TOPIC=<private topic>
tail -Fn0 /var/log/suricata/eve.json \
  | jq --unbuffered -rR 'fromjson? | select(.event_type=="alert" and .alert.severity<=2) | "\(.alert.signature) – \(.src_ip) → \(.dest_ip)"' \
  | while read -r msg; do
      curl -s --max-time 10 -H "Title: Suricata Alert" -d "$msg" "https://ntfy.sh/$TOPIC" > /dev/null
    done
```

Restarting the service also drops the backlog, because `tail -n0` starts from new events only. The topic was rotated at the same time, since the old one was visible in the process list.

**Open item:** requests from the sensor to the push service were timing out right after the flood, most likely rate limiting on the service's side. End-to-end delivery to the phone is being re-verified.

**Lessons:** tune with scoped suppressions rather than disabling rules; check direction before trusting an alert's name; and treat the notification path as part of the detection system, because an alert that is logged but never delivered is a missed alert.
