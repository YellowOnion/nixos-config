{ config, lib, pkgs, ... }:
{
  security.pam.enableSSHAgentAuth = true;

  environment.systemPackages = with pkgs; [
    steamcmd
<<<<<<< Updated upstream
=======
    steam-run
>>>>>>> Stashed changes
  ];
}
