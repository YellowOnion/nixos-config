#/usr/bin/env bash

FILE="$1"
BFILE=$(basename "$FILE")

STORE_PATH="$(nix store add --mode flat "$FILE")"

>&2 echo $STORE_PATH

nix path-info "$STORE_PATH" \
    --json --json-format 2 \
    | jq '.info[].ca | { hash : .hash, name : $name, url : $name }' \
	 --arg name "$BFILE"
