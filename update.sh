#!/usr/bin/env nix-shell
#
set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

nix flake update
