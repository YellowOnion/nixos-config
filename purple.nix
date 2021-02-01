# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let secrets = import ./secrets;
  vendor-reset = config.boot.kernelPackages.callPackage ./vendor-reset {};

in 
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./common.nix
    ];


  networking.hostName = "Purple-Sunrise"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp4s0.useDHCP = true;

  boot.kernelPatches = [ {
    name = "vendor-reset-reqs";
    patch = null;
    extraConfig = ''
      FTRACE y
      KPROBES y
      PCI_QUIRKS y
      KALLSYMS y
      KALLSYMS_ALL y
      FUNCTION_TRACER y
    ''; } ];

  # Enable the GNOME 3 Desktop Environment.
  services.xserver = { 
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = false;
    };

    desktopManager.gnome3.enable = true;
  };
  

  # Configure keymap in X11
  services.xserver.layout = "us";
  services.xserver.xkbVariant = "dvorak";
  # services.xserver.xkbOptions = "eurosign:e";
   

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.daemon.config = {
   default-sample-rate = "48000";
   default-sample-format = "float32le"; 
   remixing-produce-lfe = "no";
   remixing-consume-lfe = "no";
   default-fragments = "3";
   default-fragment-size-msec = "10";
   realtime-scheduling = "yes";
   };
  # help pulse audio use realtime scheduling
  security.rtkit.enable = true; 

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [      
    keepassxc
    firefox
    discord

    spotify
    deadbeef
    steam
    spacevim
    
    element-desktop
    signal-desktop
    
    virt-manager
   ];
  
  #hax for steam to launch
  hardware.opengl.driSupport32Bit = true;
  programs.steam.enable = true;

  # KVM stuff
  # boot.blacklistedKernelModules = ["amdgpu" "radeon" ];
  boot.extraModulePackages = [ vendor-reset ];
  #boot.initrd.kernelModules = [ vfio-pci ];
  boot.kernelModules = [ "vendor-reset" ];
  boot.kernelParams = [
    "amd_iommu=on"
    "vfio_virqfd"
    "vfio_pci"
    "vfio_iommu_type1"
    "vfio"
    "hugepagesz=2MB"
    "hugepages=8192"
    ];
  boot.extraModprobeConfig = ''
#    softdep amdgpu pre: vfio-pci
    options vfio-pci ids=1002:67df,1002:aaf0
  '';
  
  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true;
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
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.03"; # Did you read the comment?

}

