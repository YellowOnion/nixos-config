# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  lib,
  pkgs,
  ...
}:

let
  secrets = import ./secrets;
in
{
  imports = [
    ./laptop2-hw.nix
    ./common.nix
    ./common-gui.nix
    ./zen.nix
  ];

  networking.hostName = "Kawasaki-Lemon"; # Define your hostname.
  hardware.cpu.amd.updateMicrocode = true;

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices.root = {
    # crypttabExtraOpts = [ "fido2-device=auto" ];
    device = "/dev/disk/by-partuuid/bd81633a-6a8c-4f66-b217-e7d89365d5ac";
    preLVM = true;
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  boot.kernelParams = [
    "amd_pstate=passive"
  ];

  hardware.cpu.amd.ryzen-smu.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.networkmanager.enable = true;

  services.logind = {
    settings.Login = {
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
      HandleLidSwitchExternalPower = "lock";
    };
  };

  # services.tlp.enable = true;

  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.03"; # Did you read the comment?

}
