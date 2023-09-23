# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, bcachefs-nixpkgs, ... }:

let secrets = import ./secrets;
  #dsp = pkgs.callPackage /home/daniel/dev/bmc0-dsp/default.nix {} ;
  #latest     = import <nixpkgs-master> { config.allowUnfree = true; };
  #unstable   = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  disabledModules = [ "tasks/filesystems/bcachefs.nix" ];
  imports =
    [ # Include the results of the hardware scan.
      ./purple-hw.nix
      ./common.nix
      ./common-gui.nix
      "${bcachefs-nixpkgs.path}/nixos/modules/tasks/filesystems/bcachefs.nix"
    ];

  boot.kernelPackages = lib.mkOverride 0 bcachefs-nixpkgs.linuxPackages_testing_bcachefs;
  nixpkgs.overlays = [
    (super: final: {
      inherit (bcachefs-nixpkgs) systemdBcachefs;
      bcachefs-tools = let bt = bcachefs-nixpkgs.bcachefs-tools;
                           in bt.override (lib.getAttrs (lib.attrNames (lib.filterAttrs (_:a: !a) bt.override.__functionArgs)) final);
      })
  ];
  networking.hostName = "Purple-Sunrise"; # Define your hostname.

  # networking.bridges.br0.interfaces = [ "enp6s0" ];
  # networking.interfaces.br0.useDHCP = true;

  #boot.kernelPatches = [
  #  {
  #    name = "vendor-reset-reqs-and-other-stuff";
  #    patch = null;
  #    extraConfig = ''
  #    FTRACE y
  #    KPROBES y
  #    FUNCTION_TRACER y
  #    HWLAT_TRACER y
  #    TIMERLAT_TRACER y
  #    IRQSOFF_TRACER y
  #    OSNOISE_TRACER y
  #    PCI_QUIRKS y
  #    KALLSYMS y
  #    KALLSYMS_ALL y
  #  ''; }
  #]; # ++ futex.kernelPatches ++ lru.kernelPatches;

  boot.kernel.sysctl = {
    "sched_latency_ns" = "1000000";
    "sched_min_granularity_ns" = "100000";
    "sched_migration_cost_ns"  = "7000000";
  };

  #environment.variables = {
  #  __GL_SYNC_DISPLAY_DEVICE = "DisplayPort-0";
  #};
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
    rtorrent
   ];

  # KVM stuff
  # boot.blacklistedKernelModules = ["amdgpu" "radeon" ];
  #boot.extraModulePackages = [ config.boot.kernelPackages.vendor-reset config.boot.kernelPackages.v4l2loopback ];
  #boot.initrd.kernelModules = [ vfio-pci ];
  #boot.kernelModules = [ "vendor-reset" ];
  #boot.kernelParams = [
  #  "amd_iommu=on"
  #  "vfio_virqfd"
  #  "vfio_pci"
  #  "vfio_iommu_type1"
  #  "vfio"
  #  "trace_event=kmem:kmalloc,kmem:kmem_cache_alloc,kmem:kfree,kmem:kmem_cache_free"
  #  "trace_buf_size=128M"
  #  ];
  #boot.extraModprobeConfig = ''
#    softdep amdgpu pre: vfio-pci
  #  options vfio-pci ids=1002:67df,1002:aaf0
  #'';
  
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
      onBoot = "ignore";
      qemu.verbatimConfig = ''
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

    #environment.variables = {
  #  VST_PATH    = "/nix/var/nix/profiles/default/lib/vst:/var/run/current-system/sw/lib/vst:~/.vst";
  #  LXVST_PATH  = "/nix/var/nix/profiles/default/lib/lxvst:/var/run/current-system/sw/lib/lxvst:~/.lxvst";
  #  LADSPA_PATH = "/nix/var/nix/profiles/default/lib/ladspa:/var/run/current-system/sw/lib/ladspa:~/.ladspa";
  #  LV2_PATH    = "/nix/var/nix/profiles/default/lib/lv2:/var/run/current-system/sw/lib/lv2:~/.lv2";
  #  DSSI_PATH   = "/nix/var/nix/profiles/default/lib/dssi:/var/run/current-system/sw/lib/dssi:~/.dssi";
  #};

  # Open ports in the firewall.
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # security.sudo.wheelNeedsPassword = false;
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.03"; # Did you read the comment?

}

