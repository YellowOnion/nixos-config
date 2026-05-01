#!/usr/bin/env bash

set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# openttd
cd openttd
./update.sh
cd ..

cd ./proton/
./update.hs
