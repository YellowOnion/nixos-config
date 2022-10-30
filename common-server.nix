{ config, lib, pkgs, ... }:

{
  security.pam.enableSSHAgentAuth = true;
  environment.systemPackages = with pkgs; [
    steam-run
  ];
}
