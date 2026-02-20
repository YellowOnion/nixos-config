### A Persistent LiveUSB environment
# This is for Installing Windows or general trouble shooting of Windows or Linux
# for testing purposes:
# qemu-system-x86_64 -enable-kvm     \
#   -m 4G -cpu max -smp 2            \
#     -bios ~/tmp/ovmf-fd/FV/OVMF.fd \
#     -drive format=raw,file=/dev/$(lsblk -dno PTUUID,PATH \
#     | grep 1fdac1af-4d15-40e1-9e4f-63aef4dfd91f \
#     | awk '{ print $2 ;} )'
{
  modulesPath,
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  calamares-nixos-autostart = pkgs.makeAutostartItem {
    name = "calamares";
    package = pkgs.calamares-nixos;
  };
  win11-installer-UUID = "76FB35517CFE504D";
in
with lib;
{
  imports = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/installer/scan/detected.nix"
    "${moludesPath}/installer/scan/not-detected.nix"
  ];

  hardware.enableAllHardware = true;

  fileSystems."/" = {
    device = "UUID=24657530-6909-416b-9263-711c3694ce6d";
    fsType = "bcachefs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D943-3699";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
      "flush"
    ];
  };

  fileSystems."/win11-installer" = {
    device = "/dev/disk/by-uuid/${win11-installer-UUID}";
    fsType = "ntfs";
    options = ["users" "noauto" ];
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.memtest86.enable = true;
  boot.loader.grub.extraEntries = ''
    menuentry "Windows 11 Installer" {
        insmod ntfs
        insmod chain
        search --no-floppy --fs-uuid --set=root ${win11-installer-UUID}
        chainloader /efi/boot/bootx64.efi
    }
  '';

  console.packages = options.console.packages.default ++ [ pkgs.terminus_font ];

  powerManagement.enable = true;

  boot.plymouth.enable = true;

  boot.supportedFilesystems = pkgs.lib.mkForce [
    "bcachefs"
    "btrfs"
    "vfat"
    "ext4"
    "xfs"
    "ntfs"
    "exfat"
  ];

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    # Allow the graphical user to login without password
    initialHashedPassword = "";
  };
  # Allow passwordless sudo from nixos user
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  # Don't require sudo/root to `reboot` or `poweroff`.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  environment.defaultPackages = with pkgs; [
    # Include gparted for partitioning disks.
    gparted

    # Include some editors.
    vim
    nano

    # Firefox for reading the manual.
    firefox

    mesa-demos

    # Calamares for graphical installation
    calamares-nixos
    calamares-nixos-autostart
    calamares-nixos-extensions
    # Get list of locales
    glibcLocales

  ];

  # required for kpmcore to work correctly
  programs.partition-manager.enable = true;

  services.desktopManager.plasma6.enable = true;

  # Automatically login as nixos.
  services.displayManager = {
    sddm.enable = true;
    autoLogin = {
      enable = true;
      user = "nixos";
    };
  };

  # Provide networkmanager for easy network configuration.
  networking.networkmanager.enable = true;
  nix.settings.trusted-users = [ "nixos" ];

  # Avoid bundling an entire MariaDB installation on the ISO.
  programs.kde-pim.enable = false;
  system.activationScripts.installerDesktop =
    let

      # Comes from documentation.nix when xserver and nixos.enable are true.
      manualDesktopFile = "/run/current-system/sw/share/applications/nixos-manual.desktop";

      homeDir = "/home/nixos/";
      desktopDir = homeDir + "Desktop/";

    in
    ''
      mkdir -p ${desktopDir}
      chown nixos ${homeDir} ${desktopDir}

      ln -sfT ${manualDesktopFile} ${desktopDir + "nixos-manual.desktop"}
      ln -sfT ${pkgs.gparted}/share/applications/gparted.desktop ${desktopDir + "gparted.desktop"}
      ln -sfT ${pkgs.calamares-nixos}/share/applications/calamares.desktop ${
        desktopDir + "calamares.desktop"
      }
    '';
}
