#!/usr/bin/env sh

# How much of Magic the pool covers (#5039): runs census.jq over MTGJSON's
# AtomicCards.json with the inputs it reads from the tree. Run from the
# repository root:
#   script/census/census.sh _scratch/AtomicCards.json

set -o errexit
set -o nounset

atomic=$1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

jq -s 'map([.faces[].name] | join(" // "))' data/cards/*.json > "$work/pool.json"

jq \
  --slurpfile pool "$work/pool.json" \
  --rawfile rules docs/rules.txt \
  -f script/census/census.jq \
  "$atomic"
