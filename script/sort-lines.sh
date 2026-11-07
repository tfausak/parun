#!/usr/bin/env sh

# Byte-order line lists: `LC_ALL=C sort -u` output. A list kept sorted takes
# parallel branches' additions on different lines, so they merge without
# conflict; appending at the end makes every pair of branches conflict.
#
# Backs the `sorted` hook in .hooky.kdl. Usage: `sort-lines.sh MODE FILE...`,
# where MODE is `check` (report unsorted files, exit 1) or `fix` (sort them in
# place). Parun.IngestSpec holds data/oracle-unrendered.txt to the same order.

set -o errexit
set -o nounset

self=$0
mode=$1
shift

case $mode in
  check | fix) ;;
  *)
    echo "$self: unknown mode: $mode" >&2
    exit 2
    ;;
esac

status=0
for file; do
  if LC_ALL=C sort -u -c "$file" 2>/dev/null; then
    continue
  fi
  case $mode in
    check)
      echo "not sorted: $file"
      status=1
      ;;
    fix)
      LC_ALL=C sort -u -o "$file" "$file"
      ;;
  esac
done

exit $status
