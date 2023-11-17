{ config, lib, pkgs, bcachefs-nixpkgs, ... }:

let
  overrideAllInputs = final: p: p.override (lib.getAttrs (lib.attrNames (lib.filterAttrs (_:a: !a) p.override.__functionArgs)) final);
in
{
  disabledModules = [ "tasks/filesystems/bcachefs.nix" ];
  imports = [
   "${bcachefs-nixpkgs.path}/nixos/modules/tasks/filesystems/bcachefs.nix"
  ];

  boot.kernelPackages = lib.mkOverride 0 bcachefs-nixpkgs.linuxPackages_testing_bcachefs;

  # We need custom util-linux inside systemd to boot from UUID.

  systemd.package = pkgs.systemdBcachefs;

  # compile bcachefs tools with pkgs from nixpkgs, not bcacehfs-nixpkgs.
  #
  nixpkgs.overlays = [
    (super: final: {
      bcachefs-tools = overrideAllInputs final bcachefs-nixpkgs.bcachefs-tools;
      util-linuxMinimalBcachefs = overrideAllInputs final bcachefs-nixpkgs.util-linuxMinimal;
      systemdBcachefs = super.systemd.override { util-linux = super.util-linuxMinimalBcachefs; };
      })
  ];

  boot.kernelPatches = [
    {
      name = "bcachefs-helpers";
      patch = null;
      extraConfig = ''
      FTRACE y
      BCACHEFS_DEBUG_TRANSACTIONS n
    ''; }
  ];
}
