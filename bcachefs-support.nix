{ config, lib, pkgs, ... }:

let
  kernel = {
    date = "2021-04-29";
    commit = "a5c0e1bb306e79b40b2432a22f164697c8b22110";
    base = "f40ddce88593482919761f74910f42f4b84c004b";
    hash = "17gg5dzwb0y6vsa8wa2llqxspp94chcdb3w7f0mb5jrhxqcvpygw";
    version = "5.11";
  };

  tools = {
    date = "2021-04-30";
    commit = "bb74624daa138837d04c2a9931723115b9b6d645";
    hash   = "0pfx3by9kq3r13c4xb8jyhas52wk5m2v72zk27b93g9w2ffzcjg2";
  };
  nixkernel = "linux_${lib.versions.major kernel.version}_${lib.versions.minor kernel.version}";
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
            url = "https://evilpiepirate.org/git/bcachefs.git/rawdiff/?id=${kernel.commit}&id2=${kernel.base}";
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
