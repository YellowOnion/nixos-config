{
  config,
  lib,
  pkgs,
  ...
}:
{
  security.pam.sshAgentAuth.enable = true;

  environment.systemPackages = with pkgs; [
    steamcmd
    steam-run
  ];

  services.tailscale.enable = lib.mkForce true;
  networking.nftables = {
    enable = true;
  };
}
