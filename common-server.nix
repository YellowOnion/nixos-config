{ config, lib, pkgs, ... }:
{
  security.pam.enableSSHAgentAuth = true;

  environment.systemPackages = with pkgs; [
    steamcmd
    steam-run
  ];
}
