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
}
