{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ./bcachefs-support.nix
    ./common.nix
  ];

   boot.supportedFilesystems = [ "bcachefs" ];
   systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

}
