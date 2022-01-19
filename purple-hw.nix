# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "bcache" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    #{ device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_500GB_S5H7NS0NA78631F-part3:/dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K6SAF6KD:/dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K7RT8J22:/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N0998010";
    { device = "/dev/sda:/dev/sdc:/dev/sdb:/dev/sdd:/dev/nvme0n1p3";
      fsType = "bcachefs";
      options = [ "errors=ro" "noatime" "nodiratime" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D147-EA04";
      fsType = "vfat";
      options = [  "noatime" "nodiratime" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/65946d23-8ff5-4505-98bd-e9a039304d2c"; }
    ];

#  fileSystems."/media/old/share" =
#    { device = "/dev/disk/by-label/Share";
#      fsType = "ntfs";
#      options = [ "noatime" "nodiratime" "rw" "uid=1000" ];
#    };

}
