#!/usr/bin/env bash

set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

cd ./proton/
./update.hs
