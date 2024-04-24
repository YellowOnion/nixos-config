#!/usr/bin/env sh

DIR=$(realpath $(dirname "$0"))
cd $DIR

nix build ".#nixosConfigurations.NixOS-installer.config.system.build.isoImage"
