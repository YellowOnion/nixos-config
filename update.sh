#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-github
#
set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

KOWNER=${KOWNER:=YellowOnion}
KREPO=${KREPO:=linux}

TOWNER=${TOWNER:=koverstreet}
TREPO=${TREPO:=bcachefs-tools}

if [[ -n ${1} ]]; then KREV="--rev $1"; fi
if [[ -n ${2} ]]; then TREV="--rev $2"; fi

nix-prefetch-github --json $KREV $KOWNER $KREPO > bcachefs.json
nix-prefetch-github --json $TREV $TOWNER $TREPO > bcachefs-tools.json
