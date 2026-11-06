# Incident Report: Remote Access to the Servers VLAN Failing After the Tailscale Cutover

**Dates:** 2026-10-31 to 2026-11-05
**Affected systems:** Pi 1 (Tailscale subnet router, Trusted VLAN — 192.168.10.20), Pi 2 (IDS sensor, Lab VLAN — 192.168.50.20), NAS (Servers VLAN — 192.168.20.22)
**Severity:** Low (no security impact — remote access to the NAS unavailable; no data exposed)
**Status:** Resolved (2026-11-05)

## Summary

After replacing the WireGuard server with Tailscale, the NAS could not be reached through the new subnet route, from outside the house or from Pi 1 itself. Two independent problems were stacked on top of each other:

1. **A second, broken subnet router.** The subnet-router command meant for Pi 1 had also been run on Pi 2. Pi 2 was advertising both the Trusted and Servers subnets, carried the `tag:lab` tag, and had IP forwarding disabled, so any traffic Tailscale sent through it was dropped.
2. **A firewall rule dropping the replies.** With the duplicate router removed, Pi 1 still could not reach anything on the Servers VLAN. Testing from a host on the NAS's own VLAN proved the NAS was healthy. The policy list then showed that requests were allowed, but a custom "Servers to Trusted – Block" rule was dropping every reply.

## Timeline

| Date | Action | Result |
|---|---|---|
| 10-31 | `ping -c 3 192.168.20.22` from Pi 1 | 100% packet loss |
| 10-31 | `tailscale status` on Pi 2 | Health check: "Subnet routing is enabled, but IP forwarding is disabled." Pi 2 was advertising `192.168.10.0/24` and `192.168.20.0/24` |
| 10-31 | Tried to remove Pi 2's tag in the admin console | Refused: the last tag can only be removed by re-authenticating the device |
| 10-31 | Ran `tailscale up --reset` on Pi 2 over a Tailscale SSH session | Session timed out: the reset dropped the tunnel the session was riding on |
| 11-05 | `tailscale up --reset --force-reauth --accept-dns=false` on Pi 2, signed in as the owner | Pi 2 untagged, owned by the user account, no routes advertised |
| 11-05 | Same reset on Pi 1, keeping `--advertise-routes`, then approved both routes by hand and disabled key expiry | Pi 1 is now the only subnet router; no tags anywhere in the tailnet |
| 11-05 | `ping -c 3 192.168.20.22` from Pi 1 | Still 100% packet loss, so the duplicate router was not the only cause |
| 11-05 | `ip route get 192.168.20.22` on Pi 1 | `via 192.168.10.1 dev eth0` — correct path through the gateway, not into the tunnel |
| 11-05 | `ping -c 3 192.168.20.1` from Pi 1 | 0% loss — the gateway answers on the Servers VLAN interface |
| 11-05 | TCP checks to the NAS on 445 and 9999 from Pi 1 | Both **timed out** (silently dropped, not refused) |
| 11-05 | Confirmed in UniFi: NAS online at 192.168.20.22, 10 GbE link up | Not a wrong-IP problem |
| 11-05 | Ping plus TCP 445 and 9999 to the NAS from the Proxmox host (same VLAN, 192.168.20.10) | All succeeded — **the NAS is healthy and listening** |
| 11-05 | TCP 8006 to the Proxmox host from Pi 1 | Timed out — Pi 1 cannot reach **any** Servers VLAN host, so the block is the UniFi firewall, not the NAS |
| 11-05 | Checked zones and Proxmox's routing | Trusted and Servers are both in the Internal zone; Proxmox replies via the LAN, not Tailscale; no Tailscale on the NAS |
| 11-05 | Reviewed the Internal → Internal policy list | "Trusted to Servers – Allow" passes the requests, but "Servers to Trusted – Block" (all connection states, ~190,000 hits) drops the replies before the built-in return-traffic rules are reached |
| 11-05 | Set that rule's Connection State to Custom: **New + Invalid** only | Pi 1 → NAS ping 0% loss; TCP 445 to the NAS and 8006 to Proxmox both open |

## Root causes

**Cause 1 (resolved): duplicate subnet router.** Two nodes advertised the same routes, and one of them could not forward. Tagging the device also transferred its ownership from the user to the tag, which is why removing the tag required a full re-authentication from the device itself.

**Cause 2 (resolved): a stateless block rule.** A custom policy blocking Servers → Trusted matched *all* connection states. Custom policies are evaluated before UniFi's built-in rules, so the built-in "Allow Return Traffic" rule, and the return rule created by the allow policy's "Auto Allow Return Traffic" option, were never reached. Every reply from the Servers VLAN to a Trusted host was dropped, which looked like a silent timeout from the client side. Restricting the block to **New** and **Invalid** connections keeps its purpose (servers cannot initiate connections to personal devices) while letting replies through.

## Lessons learned

- **Don't change a VPN from inside the VPN.** Any `tailscale up --reset` or re-auth must be done from a local console or over the LAN address, never over the tunnel it is about to drop.
- **Tags change ownership.** On a one-person tailnet, the convenience of tags (automatic route approval, no key expiry) can be replaced by one manual approval and a per-device expiry setting. Tags come back later, deliberately, with least-privilege access rules.
- **Test from both sides of the firewall.** "Timed out" versus "refused", plus one test from a host on the target's own VLAN, separated "the server is down" from "the network is blocking it" in two commands.
- **Block rules need a connection state.** A block in one direction silently breaks the allow in the other direction unless it is limited to new connections. High hit counts on a block rule are worth a look.
- **Subnet routers masquerade by default.** Remote Tailscale clients appear on the LAN as Pi 1's address, so the firewall policy must allow Pi 1 to every Servers host that should be reachable remotely, not just the NAS.

## Follow-up

- [x] Fix the block rule's connection state and re-test from Pi 1.
- [x] Re-test from outside the network: the NAS web page opened from a laptop at a different location, over Tailscale through Pi 1.
- [x] Remove the WireGuard server and its UDP port forward: PiVPN uninstalled, nothing listening on UDP 51820, no `wg0` interface, and the gateway shows zero port forwards.
- [ ] Replace the broad "Trusted to Servers – Allow" with least-privilege rules (Pi 1 and admin devices only), and remove the now-redundant "Pi 1 to NAS" rule.
