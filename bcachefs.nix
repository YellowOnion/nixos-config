{ config, lib, pkgs, bcachefs-nixpkgs, ... }:

{
  disabledModules = [ "tasks/filesystems/bcachefs.nix" ];
  imports = [
   "${bcachefs-nixpkgs.path}/nixos/modules/tasks/filesystems/bcachefs.nix"
  ];

  boot.kernelPackages = lib.mkOverride 0 bcachefs-nixpkgs.linuxPackages_testing_bcachefs;

  # We need custom util-linux inside systemd to boot from UUID.

  systemd.package = bcachefs-nixpkgs.systemd;

  # compile bcachefs tools with pkgs from nixpkgs, not bcacehfs-nixpkgs.
  #
  nixpkgs.overlays = [
    (super: final: {
      bcachefs-tools = let bt = bcachefs-nixpkgs.bcachefs-tools;
                           in bt.override (lib.getAttrs (lib.attrNames (lib.filterAttrs (_:a: !a) bt.override.__functionArgs)) final);
      })
  ];

  boot.kernelPatches = [
    {
      name = "bcachefs-helpers";
      patch = null;
      extraConfig = ''
      FTRACE y
      CONFIG_BCACHEFS_DEBUG_TRANSACTIONS n
    ''; }
  ];
}
