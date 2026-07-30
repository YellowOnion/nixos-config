#!/usr/bin/env bash

set -eo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

./openttd-jgr/update.sh

./openttd/update.sh

./proton/update.sh
