#!/usr/bin/env bash
# healthcheck.sh - checks lab services and sends an ntfy alert when one goes
# down or comes back. Alerts only fire on a change of state, so a long outage
# is one notification, not one every five minutes.
#
#   healthcheck.sh               run all checks (normal mode, used by the timer)
#   healthcheck.sh --dry-run     run checks, print what would be alerted, change nothing
#   healthcheck.sh --test-alert  send one test notification and exit
#
# Files:
#   /etc/healthcheck/healthcheck.conf  settings (ntfy URL lives here, never in git)
#   /etc/healthcheck/checks.list       one check per line (see checks.*.list examples)
#   /var/lib/healthcheck/              failure counters and alert state

set -uo pipefail

CONF="${HEALTHCHECK_CONF:-/etc/healthcheck/healthcheck.conf}"
CHECKS="${HEALTHCHECK_CHECKS:-/etc/healthcheck/checks.list}"
STATE_DIR="${HEALTHCHECK_STATE:-/var/lib/healthcheck}"
DRY_RUN=0
MODE="run"

# Defaults; healthcheck.conf overrides them.
NTFY_URL=""            # full topic URL, e.g. https://ntfy.sh/<topic>
FAIL_THRESHOLD=2       # consecutive failures before alerting (avoids one-off blips)
TIMEOUT=5              # seconds per check
HOST_LABEL="$(hostname -s)"

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)    DRY_RUN=1 ;;
    --test-alert) MODE="test" ;;
    -c)           CHECKS=$2; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            echo "unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

# shellcheck source=/dev/null
[[ -r $CONF ]] && source "$CONF"

notify() {  # title priority tags message
  local title=$1 prio=$2 tags=$3 msg=$4
  if (( DRY_RUN )) || [[ -z $NTFY_URL ]]; then
    echo "  would notify [p$prio] $title - $msg"
    return 0
  fi
  if ! curl -fsS --max-time 10 \
        -H "Title: $title" -H "Priority: $prio" -H "Tags: $tags" \
        -d "$msg" "$NTFY_URL" >/dev/null; then
    echo "WARN: ntfy delivery failed for '$title'" >&2
    return 1
  fi
}

if [[ $MODE == test ]]; then
  notify "$HOST_LABEL: healthcheck test" 3 test_tube "If you can read this, alerts work."
  exit $?
fi

# --- check types ------------------------------------------------------------
# Each returns 0 for healthy and may set DETAIL to explain a failure.
DETAIL=""

check_ping() { ping -c 2 -W "$TIMEOUT" "$1" >/dev/null 2>&1 || DETAIL="no reply from $1"; [[ -z $DETAIL ]]; }

check_tcp() {  # host port
  timeout "$TIMEOUT" bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null || { DETAIL="port $2 closed or filtered on $1"; return 1; }
}

check_http() {  # url [text the response must contain]
  local body
  if ! body=$(curl -fsSk --max-time "$TIMEOUT" "$1" 2>&1); then
    DETAIL="${body:0:120}"; return 1
  fi
  if [[ -n ${2:-} && $body != *"$2"* ]]; then
    DETAIL="response did not contain '$2'"; return 1
  fi
}

check_dns() {  # server name
  local out
  out=$(dig +short +time="$TIMEOUT" +tries=1 @"$1" "$2" A 2>&1)
  grep -qE '^[0-9]+(\.[0-9]+){3}$' <<<"$out" || { DETAIL="no A record for $2 from $1 (${out:0:80})"; return 1; }
}

check_service() { systemctl is-active --quiet "$1" || { DETAIL="$1 is $(systemctl is-active "$1" 2>/dev/null)"; return 1; }; }

check_disk() {  # mountpoint max-percent
  local used
  used=$(df -P "$1" 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')
  [[ -n $used ]] || { DETAIL="cannot read $1"; return 1; }
  (( used < $2 )) || { DETAIL="$1 is ${used}% full (limit $2%)"; return 1; }
}

check_fresh() {  # file max-age-seconds  (catches a log that stopped updating)
  [[ -e $1 ]] || { DETAIL="$1 missing"; return 1; }
  local age=$(( $(date +%s) - $(stat -c %Y "$1") ))
  (( age <= $2 )) || { DETAIL="$1 last written ${age}s ago (limit $2s)"; return 1; }
}

run_check() {  # type args...
  local type=$1; shift
  case $type in
    ping|tcp|http|dns|service|disk|fresh) "check_$type" "$@" ;;
    *) DETAIL="unknown check type '$type'"; return 1 ;;
  esac
}

# --- main -------------------------------------------------------------------
[[ -r $CHECKS ]] || { echo "cannot read checks file $CHECKS" >&2; exit 2; }
if (( ! DRY_RUN )); then
  mkdir -p "$STATE_DIR"
  exec 9>"$STATE_DIR/.lock"
  flock -n 9 || { echo "another run is in progress"; exit 0; }
fi

total=0 failed=0
while read -r type name a b <&3; do
  [[ -z ${type:-} || $type == \#* ]] && continue
  total=$(( total + 1 ))
  key=$(printf '%s' "$name" | tr -c 'A-Za-z0-9_.-' '_')
  count_file="$STATE_DIR/$key.count"
  alert_file="$STATE_DIR/$key.alerted"
  DETAIL=""

  if run_check "$type" "$a" "${b:-}" </dev/null; then
    echo "OK    $name"
    if [[ -e $alert_file ]]; then
      notify "$HOST_LABEL: $name recovered" 3 white_check_mark "$name is healthy again." \
        && (( ! DRY_RUN )) && rm -f "$alert_file"
    fi
    (( DRY_RUN )) || rm -f "$count_file"
  else
    failed=$(( failed + 1 ))
    count=$(( $(cat "$count_file" 2>/dev/null || echo 0) + 1 ))
    (( DRY_RUN )) || echo "$count" > "$count_file"
    echo "FAIL  $name - $DETAIL [$count/$FAIL_THRESHOLD]"
    if (( count >= FAIL_THRESHOLD )) && [[ ! -e $alert_file ]]; then
      notify "$HOST_LABEL: $name DOWN" 4 rotating_light "$type check failed $count times in a row: $DETAIL" \
        && (( ! DRY_RUN )) && touch "$alert_file"
    fi
  fi
done 3< "$CHECKS"

echo "healthcheck: $(( total - failed ))/$total passed"
(( failed == 0 ))
