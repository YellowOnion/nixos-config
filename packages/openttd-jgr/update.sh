#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update

cd "$(git rev-parse --show-toplevel)"

nix-update -vr 'jgrpp-(.*)' -F openttd-jgr
