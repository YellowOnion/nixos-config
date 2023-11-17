{ modulesPath, config, lib, pkgs, bcachefs-nixpkgs, ... }:
{
  imports = [
   "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
   "${modulesPath}/installer/cd-dvd/channel.nix"
   ./bcachefs.nix
  ];

  isoImage.edition = lib.mkOverride 40 "bchfs-minimal";

  boot.supportedFilesystems = pkgs.lib.mkForce [ "bcachefs" "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
}
