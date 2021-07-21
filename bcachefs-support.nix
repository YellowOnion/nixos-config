{ config, lib, pkgs, ... }:

let
  kernel = {
    date = "2021-06-15";
    commit = "ca3cfad39f91";
    hash = "0kvfg9rxjhf70kvgj3qb1a0j696xykg0w6aybfiykajncc4riqwb";
    version = "5.12";
  };

  tools = {
    date = "2021-06-23";
    commit = "55142cd0b5ef2a2150d4708dad0c3fd54a3ffd39";
    hash   = "1nipvm61kdfzh9aqrb7z2xm32gg6rl18jvfy8kk5gz9983s6br2s";
  };
  nixkernel = "linux_5_12";
in
{

  disabledModules = [ "tasks/filesystems/zfs.nix" ];
  nixpkgs.overlays = [
    (self: oldpkgs: {
    linux_testing_bcachefs = oldpkgs."${nixkernel}".override {
      kernelPatches = oldpkgs."${nixkernel}".kernelPatches ++ [(
        rec {
          name = "bcachefs-${kernel.date}";
          patch = oldpkgs.fetchurl {
            name = "bcachefs-${kernel.commit}-v${kernel.version}.patch";
            url = "https://raw.githubusercontent.com/YellowOnion/bcachefs-patches/master/v${kernel.version}/bcachefs-v${kernel.version}-${kernel.date}-${kernel.commit}.patch";
            sha256 = kernel.hash;
           };
        })];
      dontStrip = true;
      extraConfig = "BCACHEFS_FS m";
    };
    bcachefs-tools = oldpkgs.bcachefs-tools.overrideDerivation ( oldAttrs: {
        version = "2021-05-05";
        src = oldpkgs.fetchgit {
            url = "https://evilpiepirate.org/git/bcachefs-tools.git";
            rev = tools.commit;
            sha256 = tools.hash;
        };
     });

    })];
}
