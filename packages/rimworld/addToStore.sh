#/usr/bin/env bash

FILE="$1"
BFILE=$(basename "$FILE")

INFO=$( nix store prefetch-file --hash-type sha256 file://$(realpath "$FILE") --json )

echo -n "$INFO" | jq '{ "name": $name, "url" : $name, "hash" : .hash }' --arg name "$BFILE"
