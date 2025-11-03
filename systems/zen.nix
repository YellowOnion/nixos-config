{ config, lib, pkgs, ... }:

{
  boot = {
    kernelParams = [
      "amd_pstate=active"
    ];

    blacklistedKernelModules = [ "k10temp" ];
    initrd.kernelModules = [ "zenpower" ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
  };
}
