#!/usr/bin/env sh

# How much of Magic the pool covers (#5039): runs census.jq over MTGJSON's
# AtomicCards.json with the inputs it reads from the tree. Run from the
# repository root, with a built pawl on the PATH or named by PAWL:
#   script/census/census.sh _scratch/AtomicCards.json

set -o errexit
set -o nounset

atomic=$1
pawl=${PAWL:-pawl}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

jq -s 'map([.faces[].name] | join(" // "))' data/cards/*.json > "$work/pool.json"
jq -s 'map(.faces[].name)' data/cards/*.json > "$work/faces.json"
"$pawl" schema | jq '[.. | objects | (.const?, .enum?[]?) | strings] | unique' > "$work/tags.json"
{
  grep -rhoE '"[^"\\]+"' source/libraries/test --include='*.hs' | jq -R 'ltrimstr("\"") | rtrimstr("\"")'
  find data/scenarios -name '*.json' -exec jq '.. | strings' {} +
} | jq -s unique > "$work/tested.json"

jq \
  --slurpfile pool "$work/pool.json" \
  --slurpfile faces "$work/faces.json" \
  --slurpfile tags "$work/tags.json" \
  --slurpfile tested "$work/tested.json" \
  --rawfile rules docs/rules.txt \
  -f script/census/census.jq \
  "$atomic"
