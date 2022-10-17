# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let secrets = import ./secrets;
  latest = import <nixpkgs-master> { config.allowUnfree = true; };
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
  my-nur     = import ../../home/daniel/nur-bcachefs {pkgs = pkgs;};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./common.nix
      ./common-gui.nix
#      ./haskell-dev.nix
   #   ./bcachefs-support.nix
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
 
 #boot.kernelPackages = lib.mkOverride 0 (pkgs.linuxPackagesFor my-nur.bcachefs-kernel);
 
 nixpkgs.overlays = [
   (final: super:
      { bcachefs-tools = my-nur.bcachefs-tools ; }
   )];
 # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ 
    hplip ] ;


  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # services.tlp.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  services.ratbagd.enable = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [

#    calibre

#    kodi


#    obs-studio
    v4l-utils

#    anki-bin
#    mpv
#    piper

    (texlive.combine { inherit (texlive) scheme-medium standalone; })

#    haskell-language-server
#    stack
#    ghc
   ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  #nix.binaryCaches = [
  #  "ssh://daniel@192.168.88.155"
  #];
  
  programs.ccache = {
    enable = true;
    packageNames = [
      "linux"
    ];
  };
  nix = {
    extraOptions = ''
      extra-sandbox-paths = /var/cache/ccache
    '';
    settings = {
      substituters = [
          "https://yo-nur.cachix.org"
      ];
      trusted-public-keys = [
        "yo-nur.cachix.org-1:E/RHfQMAZ90mPhvsaqo/GrQ3M1xzXf5Ztt0o+1X3+Bs="
      ];
    };
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.03"; # Did you read the comment?

}
