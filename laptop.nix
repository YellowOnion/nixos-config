# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let secrets = import ./secrets;
  latest = import <nixpkgs-master> { config.allowUnfree = true; };
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
#  my-nur     = import ../../home/daniel/nur-bcachefs {pkgs = pkgs;};
  nixos-hardware = builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      "${nixos-hardware}/common/cpu/amd/default.nix"
      "${nixos-hardware}/common/cpu/amd/pstate.nix"
      "${nixos-hardware}/common/gpu/amd/default.nix"
      ./common.nix
      ./common-gui.nix
    ];

  networking.hostName = "Kawasaki-Lemon"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  # networking.useDHCP = false;
  # networking.interfaces.enp0s25.useDHCP = true;


  boot.kernel.sysctl = {
    "sched_latency_ns" = "1000000";
    "sched_min_granularity_ns" = "100000";
    "sched_migration_cost_ns"  = "7000000";
  };


 # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ 
    hplip ] ;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # services.tlp.enable = true;
  hardware.fancontrol = {
    enable = true;
    config = ''
      # Configuration file generated by pwmconfig, changes will be lost
      INTERVAL=1
      DEVPATH=hwmon0=devices/pci0000:00/0000:00:03.1/0000:07:00.0
      DEVNAME=hwmon0=amdgpu
      FCTEMPS=hwmon0/pwm1=hwmon0/temp1_input
      FCFANS= hwmon0/pwm1=hwmon0/fan1_input
      MINTEMP=hwmon0/pwm1=50
      MAXTEMP=hwmon0/pwm1=80
      MINSTART=hwmon0/pwm1=32
      MINSTOP=hwmon0/pwm1=10
      MINPWM=hwmon0/pwm1=0
      MAXPWM=hwmon0/pwm1=128
      '';
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  services.ratbagd.enable = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
   ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.03"; # Did you read the comment?

}

