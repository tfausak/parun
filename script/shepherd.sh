#!/usr/bin/env bash
# Shepherd one pull request in the background: exit when it merges, closes,
# conflicts, fails a check or leaves the merge queue unmerged. Usage:
#   script/shepherd.sh PR
# REST only (`gh api`), so it works where gh's GraphQL is blocked. Prints the
# outcome and exits 0 for MERGED or CLOSED, 1 for CONFLICT (dirty on a third
# poll), 2 for FAILED, naming the failed, cancelled or timed-out checks, and 3
# for DEQUEUED: out of the queue on a second poll and not armed again, though
# its own checks may be green.
# Polls every two minutes.
pr=$1
dirty=0
out=0
while :; do
  s=$(gh api "repos/parun-mtg/parun/pulls/$pr" --jq '(.state)+" "+(.merged|tostring)+" "+.mergeable_state+" "+.head.sha' 2>/dev/null)
  set -- $s
  case "$1 $2 $3" in
    "closed true"*) echo "$pr MERGED"; exit 0 ;;
    "closed false"*) echo "$pr CLOSED"; exit 0 ;;
    "open false dirty")
      dirty=$((dirty + 1))
      [ "$dirty" -ge 3 ] && { echo "$pr CONFLICT"; exit 1; } ;;
    *)
      # A merge logs its removal just before it closes the PR: wait a poll.
      e=$(gh api --paginate "repos/parun-mtg/parun/issues/$pr/events" --jq '.[]|select(.event=="auto_merge_enabled" or .event=="added_to_merge_queue" or .event=="removed_from_merge_queue")|.event' 2>/dev/null | tail -n 1)
      if [ "$e" = removed_from_merge_queue ]; then
        out=$((out + 1))
        [ "$out" -ge 2 ] && { echo "$pr DEQUEUED"; exit 3; }
      else
        out=0
      fi
      f=$(gh api "repos/parun-mtg/parun/commits/${4:-}/check-runs" --jq '[.check_runs[]|select(.conclusion=="failure" or .conclusion=="cancelled" or .conclusion=="timed_out")|.name]|join(",")' 2>/dev/null)
      [ -n "$f" ] && { echo "$pr FAILED $f"; exit 2; } ;;
  esac
  sleep 120
done
