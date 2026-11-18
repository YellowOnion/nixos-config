#!/usr/bin/env bash
#!nix-shell -i bash -p jq

FILE="$1"
FN=$(basename "$FILE")

STORE_PATH=$(nix-store --add-fixed sha256 "$FILE")

nix path-info $STORE_PATH --json --json-format 2 | jq '{name: $name, url: $name, hash: .info[].ca.hash }' --arg name "$FN"
