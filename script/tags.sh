#!/usr/bin/env bash
# Write a ctags index of the Haskell source to ./tags, so a definition is one
# lookup instead of a grep over every mention: `grep -P '^castUse\t' tags`
# answers the file and line. Run from the checkout (or worktree) to index;
# rerun after edits move code. Usage:
#   script/tags.sh
# Uses hasktags from PATH (the flake's dev shell has it), else from the
# flake's pinned nixpkgs through `nix shell`.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
if command -v hasktags >/dev/null; then
  hasktags --ctags --output=tags source >/dev/null
else
  nix --extra-experimental-features 'nix-command flakes' shell \
    --inputs-from . nixpkgs#haskellPackages.hasktags \
    --command hasktags --ctags --output=tags source >/dev/null
fi
echo "tags: $(wc -l < tags) entries"
