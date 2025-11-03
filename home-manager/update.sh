#!/usr/bin/env sh

set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

REV=$(nix flake metadata --json /etc/nixos | jq '.locks.nodes."nixpkgs-unstable".locked.rev' --raw-output)
printf "Bumping nixpkgs to $REV"
sed -i -E 's:nixpkgs/(\w|\d){40}:nixpkgs/'$REV':' flake.nix
./update-proton.sh
