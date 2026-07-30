#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq nix-update curl

cd "$(git rev-parse --show-toplevel)"

DEV=OpenTTD
REPO=OpenTTD

get_tag () {
 curl \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$1/releases/latest" \
 | jq -r '.tag_name'
}

VERSION=$(get_tag $DEV/$REPO)

echo "version: $VERSION"

nix-update -F openttd --version "$VERSION"
