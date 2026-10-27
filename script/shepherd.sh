#!/usr/bin/env bash
# Shepherd one pull request in the background: update its branch while it is
# BEHIND, and exit when it merges, closes, conflicts or fails a check. Usage:
#   script/shepherd.sh PR
# REST only (`gh api`), so it works where gh's GraphQL is blocked. Prints the
# outcome and exits 0 for MERGED or CLOSED, 1 for CONFLICT (dirty on a third
# poll) and 2 for FAILED, naming the failed, cancelled or timed-out checks.
# Polls every two minutes.
pr=$1
dirty=0
while :; do
  s=$(gh api "repos/tfausak/parun/pulls/$pr" --jq '(.state)+" "+(.merged|tostring)+" "+.mergeable_state+" "+.head.sha' 2>/dev/null)
  set -- $s
  case "$1 $2 $3" in
    "closed true"*) echo "$pr MERGED"; exit 0 ;;
    "closed false"*) echo "$pr CLOSED"; exit 0 ;;
    "open false behind") gh api -X PUT "repos/tfausak/parun/pulls/$pr/update-branch" >/dev/null 2>&1 ;;
    "open false dirty")
      dirty=$((dirty + 1))
      [ "$dirty" -ge 3 ] && { echo "$pr CONFLICT"; exit 1; } ;;
    *)
      f=$(gh api "repos/tfausak/parun/commits/${4:-}/check-runs" --jq '[.check_runs[]|select(.conclusion=="failure" or .conclusion=="cancelled" or .conclusion=="timed_out")|.name]|join(",")' 2>/dev/null)
      [ -n "$f" ] && { echo "$pr FAILED $f"; exit 2; } ;;
  esac
  sleep 120
done
