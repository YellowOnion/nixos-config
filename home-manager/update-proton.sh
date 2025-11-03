#!/usr/bin/env nix-shell
#! nix-shell -i bash -p jq curl

set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

VERSIONS_FILE=./proton.nix

RELEASES=($( curl \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases \
   | jq 'sort_by(.created_at) | .[-3:] | map(.tag_name) | .[]' --raw-output -c))

printf "{\n" > $VERSIONS_FILE
for REL in "${RELEASES[@]}"; do
  printf "  $REL = {\n" >> $VERSIONS_FILE
  URL=https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${REL}/${REL}.tar.gz
  printf "  url = \"$URL\";\n" >> $VERSIONS_FILE
  HASH=$(nix store prefetch-file --unpack --json --hash-type sha256 "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$REL/$REL.tar.gz" |  jq -r .hash)
  printf "  hash = \"$HASH\";\n" >> $VERSIONS_FILE
  printf "};\n" >> $VERSIONS_FILE
done
printf "}\n" >> $VERSIONS_FILE

nixfmt $VERSIONS_FILE
