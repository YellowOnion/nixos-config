#!/usr/bin/env bash

nix-channel --add --option sandbox false https://github.com/NixOS/nixpkgs/archive/master.tar.gz nixpkgs-master
nix-channel --add --option sandbox false https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --update --option sandbox false


