# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let secrets = import ./secrets;
  vendor-reset = config.boot.kernelPackages.callPackage ./vendor-reset {};
  scream = pkgs.callPackage /home/daniel/dev/nix/scream {} ;
  latest = import <nixpkgs-master> { config.allowUnfree = true; };
in 
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./common.nix
      ./common-gui.nix
      ./haskell-dev.nix
    ];


  networking.hostName = "Purple-Sunrise"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.bridges.br0.interfaces = [ "enp4s0" ];
  networking.interfaces.br0.useDHCP = true;
  
  nixpkgs.config.packageOverrides = pkgs: { 
    linux_testing_bcachefs = (pkgs.linux_testing_bcachefs.override {
      argsOverride = rec {
        src = pkgs.fetchFromGitHub {
             owner = "koverstreet";
             repo  = "bcachefs";
             rev   = "6a3927a96b2f362deccc7ee36e20e03f193a9e00";
             sha256 = "07m0b28nl3ysz32lrsn75rlysz6z2m2m8d9z5d4rpxnvjym1ksvf";
        };
        version = "5.10.29-bcachefs-git-6a3927a";
        modDirVersion = "5.10.0";
        extraConfig = ''
          BCACHEFS_FS m
          '';
      };
    });
    bcachefs-tools = pkgs.bcachefs-tools.overrideDerivation ( oldAttrs: {
        version = "2021-05-05";
        src = pkgs.fetchFromGitHub {
              owner = "koverstreet";
              repo = "bcachefs-tools";
              rev = "e9909cee527acd58d0776d00eb73d487abcd5bb9";
              sha256 = "163zw1c3qijns7jjx7j04bbmgx35bg8z38mvwdqspgflgvmzdrbv";
        };
     });
   };
      


  boot.kernelPatches = [ {
    name = "vendor-reset-reqs";
    patch = null;
    extraConfig = ''
      FTRACE y
      LATENCYTOP y 
      SCHEDSTATS y
      KPROBES y
      PCI_QUIRKS y
      KALLSYMS y
      KALLSYMS_ALL y
      FUNCTION_TRACER y
    ''; } ];



  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ 
    hplip ] ;


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [

    calibre

    latest.spotify
    kodi

    rtorrent

    obs-studio
    obs-v4l2sink

    anki-bin
    mpv


    (texlive.combine { inherit (texlive) scheme-medium standalone; })

    virt-manager
    scream

    legendary-gl
    protontricks
    
    latencytop
   ];
  
  #hax for steam to launch
  hardware.opengl = {
    driSupport32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    setLdLibraryPath = true;
    extraPackages = with pkgs; [ rocm-opencl-icd rocm-opencl-runtime rocm-runtime ];
  };

  # KVM stuff
  # boot.blacklistedKernelModules = ["amdgpu" "radeon" ];
  boot.extraModulePackages = [ vendor-reset config.boot.kernelPackages.v4l2loopback ];
  #boot.initrd.kernelModules = [ vfio-pci ];
  boot.kernelModules = [ "vendor-reset" ];
  boot.kernelParams = [
    "amd_iommu=on"
    "vfio_virqfd"
    "vfio_pci"
    "vfio_iommu_type1"
    "vfio"
    ];
  boot.extraModprobeConfig = ''
#    softdep amdgpu pre: vfio-pci
    options vfio-pci ids=1002:67df,1002:aaf0
  '';
  
  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      onBoot = "ignore";
      qemuVerbatimConfig = ''
      user = "daniel"
      '';
    };
  };

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
    
    '';
    shares = {
      oldMedia = {
        "guest okay" = "yes";
        path = "/media/old";
        browseable = "yes";
        "valid users" = "daniel";
      };
    };
  };
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


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

