{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot = {
    blacklistedKernelModules = [ "k10temp" ];
    initrd.kernelModules = [ "zenpower" ];
    extraModulePackages = [ config.boot.kernelPackages.zenpower ];
  };
}
