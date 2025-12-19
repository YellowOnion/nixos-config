#!/usr/bin/env sh

set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

./update-proton.sh
