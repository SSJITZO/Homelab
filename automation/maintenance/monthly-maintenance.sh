#!/usr/bin/env bash
# monthly-maintenance.sh - full OS upgrade + Pi-hole update, then reboot only
# if an update needs it. Sends ntfy messages at each step.
#
#   monthly-maintenance.sh            do it for real (what the timer runs)
#   monthly-maintenance.sh --dry-run  show what would happen, change nothing
#
# Safety rules:
#   - if any step fails, it does NOT reboot (a half-updated box stays up so you can look)
#   - it only reboots when /var/run/reboot-required says an update needs it
#   - after a reboot, maintenance-verify.sh checks the box came back and reports

set -uo pipefail

CONF="${MAINT_CONF:-/etc/maintenance/maintenance.conf}"
STATE_DIR="${MAINT_STATE:-/var/lib/maintenance}"
LOG="${MAINT_LOG:-/var/log/monthly-maintenance.log}"
DRY_RUN=0

# Defaults; maintenance.conf overrides them.
NTFY_URL=""
HOST_LABEL="$(hostname -s)"
REBOOT="auto"          # auto = only if needed | always | never

[[ ${1:-} == --dry-run ]] && DRY_RUN=1
# shellcheck source=/dev/null
[[ -r $CONF ]] && source "$CONF"

# Everything printed below also goes to the log file.
exec > >(tee -a "$LOG") 2>&1
echo "=== $(date '+%F %T') maintenance start (dry-run=$DRY_RUN) ==="

notify() {  # title priority tags message
  if (( DRY_RUN )) || [[ -z $NTFY_URL ]]; then
    echo "  would notify [p$2] $1 - $4"; return 0
  fi
  curl -fsS --max-time 10 -H "Title: $1" -H "Priority: $2" -H "Tags: $3" \
       -d "$4" "$NTFY_URL" >/dev/null || echo "WARN: ntfy delivery failed" >&2
}

run() {  # print the command, then run it unless this is a dry run
  echo "+ $*"
  (( DRY_RUN )) && return 0
  "$@"
}

export DEBIAN_FRONTEND=noninteractive       # never stop to ask a question at 2 AM
APT_OPTS=(-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)
failed=()

run apt-get update -q || failed+=("apt-get update")
pending=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
echo "packages to upgrade: $pending"

run apt-get "${APT_OPTS[@]}" full-upgrade || failed+=("apt-get full-upgrade")
run apt-get -y autoremove                   || failed+=("apt-get autoremove")
if command -v pihole >/dev/null; then
  run pihole -up                            || failed+=("pihole -up")
fi

if (( ${#failed[@]} )); then
  notify "$HOST_LABEL: maintenance FAILED" 4 warning \
    "Failed: ${failed[*]}. Not rebooting. Check $LOG"
  echo "=== failed: ${failed[*]} ==="
  exit 1
fi

need_reboot=0
[[ -e /var/run/reboot-required ]] && need_reboot=1
[[ $REBOOT == always ]] && need_reboot=1
[[ $REBOOT == never  ]] && need_reboot=0

if (( need_reboot )); then
  notify "$HOST_LABEL: rebooting after updates" 3 arrows_counterclockwise \
    "Upgraded $pending packages. Rebooting now; a check will report when it is back."
  if (( ! DRY_RUN )); then mkdir -p "$STATE_DIR" && touch "$STATE_DIR/verify-after-boot"; fi
  echo "=== rebooting ==="
  run systemctl reboot
else
  notify "$HOST_LABEL: maintenance done" 2 white_check_mark \
    "Upgraded $pending packages. No reboot needed."
  echo "=== done, no reboot needed ==="
fi
