args@{ lib, pkgs, ... }:
let
  openttd = import ./openttd/package.nix args;
  in
{
  proton = import ./proton args;
  rimworld = pkgs.callPackage ./rimworld/package.nix {};
  openttd-jgr = openttd.jgr;
  openttd     = openttd.vanilla;
  openttd-launcher = openttd.launcher;
  auth-server = pkgs.callPackage ./auth-server/package.nix {};
}

