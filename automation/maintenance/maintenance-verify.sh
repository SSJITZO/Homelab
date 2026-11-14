#!/usr/bin/env bash
# maintenance-verify.sh - runs once at boot, only after a maintenance reboot
# (systemd checks for the marker file). Confirms the box came back healthy.

set -uo pipefail

CONF="${MAINT_CONF:-/etc/maintenance/maintenance.conf}"
STATE_DIR="${MAINT_STATE:-/var/lib/maintenance}"
NTFY_URL=""
HOST_LABEL="$(hostname -s)"
VERIFY_SERVICES="pihole-FTL tailscaled"   # override in maintenance.conf
VERIFY_UFW=1
VERIFY_DNS="127.0.0.1"                    # resolver to test; empty to skip
# shellcheck source=/dev/null
[[ -r $CONF ]] && source "$CONF"

sleep 60   # give services a minute to settle after boot

problems=()
for svc in $VERIFY_SERVICES; do
  systemctl is-active --quiet "$svc" || problems+=("$svc not running")
done
if (( VERIFY_UFW )); then
  ufw status | grep -q '^Status: active' || problems+=("firewall not active")
fi
if [[ -n $VERIFY_DNS ]]; then
  dig +short +time=5 +tries=1 @"$VERIFY_DNS" example.com A | grep -qE '^[0-9]+(\.[0-9]+){3}$' \
    || problems+=("DNS via $VERIFY_DNS not answering")
fi

if (( ${#problems[@]} )); then
  msg="Back up after updates, but: ${problems[*]}"; title="$HOST_LABEL: CHECK AFTER REBOOT FAILED"; prio=5; tags=rotating_light
else
  msg="Back up after updates. Kernel $(uname -r); services, firewall and DNS OK."; title="$HOST_LABEL: maintenance complete"; prio=3; tags=white_check_mark
fi
echo "$title - $msg"
[[ -n $NTFY_URL ]] && curl -fsS --max-time 10 -H "Title: $title" -H "Priority: $prio" \
  -H "Tags: $tags" -d "$msg" "$NTFY_URL" >/dev/null
rm -f "$STATE_DIR/verify-after-boot"
(( ${#problems[@]} == 0 ))
