{ modulesPath, config, lib, pkgs, ... }:
with lib;
{
  imports = [
   "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
   "${modulesPath}/installer/cd-dvd/channel.nix"
   ./bcachefs.nix
   ./common.nix
   ./common-gui.nix
  ];

  isoImage.edition = lib.mkOverride 40 "bchfs-minimal";
  isoImage.makeUsbBootable = true;
  isoImage.makeEfiBootable = true;
  isoImage.squashfsCompression = "zstd -Xcompression-level 18";

  boot.supportedFilesystems = pkgs.lib.mkForce [ "bcachefs" "btrfs" "vfat" "ext4" "xfs" "ntfs" "exfat" ];
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  fileSystems = {
    "/home" = {
      fsType = "xfs";
      device = "/dev/disk/by-label/${config.isoImage.volumeID}-home";
      neededForBoot = true;
    };
  };
}
