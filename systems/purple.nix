# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}@args:

let
  secrets = import ./secrets;
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  imports = [
    # Include the results of the hardware scan.
    ./common.nix
    ./common-gui.nix
    # broken in kernel v6.9-rc2
    ./zen.nix
  ];

  boot.kernelPackages = lib.mkForce latestKernelPackage;

#  boot.tmp = {
#    useTmpfs = true;
#    tmpfsSize = "50%";
#    tmpfsHugeMemoryPages = "within_size";
#  };

  nixpkgs.overlays = [ ];
  hardware.cpu.amd.updateMicrocode = true;
  # networking.bridges.br0.interfaces = [ "enp6s0" ];
  # networking.interfaces.br0.useDHCP = true;

  #programs.corectrl.enable = true;
  security.polkit.enable = true;

  boot.kernel.sysfs = {
      kernel.mm.transparent_hugepage = {
        enabled = "always";
        defrag = "defer+madvise";
        shmem_enabled = "within_size";
  };

  };
  #environment.variables = {
  #  __GL_SYNC_DISPLAY_DEVICE = "DisplayPort-0";
  #};

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    rtorrent
  ];

  # hardware.cpu.amd.ryzen-smu.enable = true;

  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xfffffffb"
    "default_hugepagesz=1G" "hugepagesz=1G"
    "amd_pstate=active"
  ];
  # KVM stuff
  #boot.extraModulePackages = [ config.boot.kernelPackages.vendor-reset config.boot.kernelPackages.v4l2loopback ];
  #boot.initrd.kernelModules = [ vfio-pci ];

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

  programs.virt-manager.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation = {
    libvirtd = {
      enable = true;
      #    qemu.ovmf.enable = true;
      #    onBoot = "ignore";
      #    qemu.verbatimConfig = ''
      #    user = "daniel"
      #    '';
    };
  };

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    defaultHTTPListenPort = 9999;
    virtualHosts."home.gluo.nz" = {
      serverAliases = [ "share.gluo.nz" ];
      extraConfig = ''
        autoindex on;
      '';
      locations."/xml/" = {
        alias = "/var/www/";
        extraConfig = ''
          autoindex_format xml;
        '';
      };
      locations."/" = {
        root = "/var/www/";
        extraConfig = ''
          add_before_body /.header.html;
        '';
      };
    };
  };

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
  system.stateVersion = "26.06"; # Did you read the comment?

}
