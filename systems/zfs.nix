{
  config,
  pkgs,
  lib,
  ...
}@args:

let 
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestZfsKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in {
  boot.kernelPackages = lib.mkForce latestZfsKernelPackage;
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-01 04:00:00"; # monthly 4am
    randomizedDelaySec = "1h";
  };
  services.fstrim.enable = false;
  services.zfs.trim = {
    interval = "Mon *-*-* 04:00:00";
    randomizedDelaySec = "1h";
  };
}
