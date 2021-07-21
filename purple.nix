# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let secrets = import ./secrets;
  vendor-reset = config.boot.kernelPackages.callPackage ./vendor-reset {};
  scream = pkgs.callPackage /home/daniel/dev/nix/scream {} ;
  dsp = pkgs.callPackage /home/daniel/dev/bmc0-dsp/default.nix {} ;
  latest = import <nixpkgs-master> { config.allowUnfree = true; };
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./common.nix
      ./common-gui.nix
      ./haskell-dev.nix
      ./bcachefs-support.nix
    ];


  networking.hostName = "Purple-Sunrise"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.bridges.br0.interfaces = [ "enp4s0" ];
  networking.interfaces.br0.useDHCP = true;


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

  boot.kernel.sysctl = {
    "sched_latency_ns" = "1000000";
    "sched_min_granularity_ns" = "100000";
    "sched_migration_cost_ns"  = "7000000";
  };

  environment.variables = {
    __GL_SYNC_DISPLAY_DEVICE = "DisplayPort-0";
  };
  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ 
    hplip ] ;


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  services.ratbagd.enable = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [

    calibre

    latest.spotify
    kodi

    rtorrent

    obs-studio
    v4l-utils
    libstrangle

    anki-bin
    mpv
    piper

    dsp
    lsp-plugins
    audacity
    carla

    (texlive.combine { inherit (texlive) scheme-medium standalone; })

    virt-manager
    scream

    haskell-language-server
    stack
    ghc

    legendary-gl
    libstrangle
    protontricks
    mangohud
    lutris
    wine-staging

    ipset
   ];

  hardware.firmware =
    [
      (pkgs.edid-generator.override
        { modelines = [ "Modeline 1920x1200RB2 148.20 1920 1928 2000 2000 1200 1221 1229 1235 +Hsync -Vsync" ];
        }
      )
    ];
  #hax for steam to launch
  hardware.opengl = {
    driSupport32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [ libva pipewire ];
    setLdLibraryPath = true;
    #package = unstable.mesa.drivers;
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
  environment.variables = {
    VST_PATH    = "/nix/var/nix/profiles/default/lib/vst:/var/run/current-system/sw/lib/vst:~/.vst";
    LXVST_PATH  = "/nix/var/nix/profiles/default/lib/lxvst:/var/run/current-system/sw/lib/lxvst:~/.lxvst";
    LADSPA_PATH = "/nix/var/nix/profiles/default/lib/ladspa:/var/run/current-system/sw/lib/ladspa:~/.ladspa";
    LV2_PATH    = "/nix/var/nix/profiles/default/lib/lv2:/var/run/current-system/sw/lib/lv2:~/.lv2";
    DSSI_PATH   = "/nix/var/nix/profiles/default/lib/dssi:/var/run/current-system/sw/lib/dssi:~/.dssi";
  };

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

