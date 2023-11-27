{ config, lib, pkgs, bcachefs-nixpkgs, ... }:

###
# needs nixpkgs PR#269381

let
  overrideAllInputs = final: p: p.override (lib.getAttrs (lib.attrNames (lib.filterAttrs (_:a: !a) p.override.__functionArgs)) final);
  shorthash = builtins.substring 0 7;
  customKernelPackages = (pkgs.linuxKernel.packagesFor
    (let kernel = pkgs.linuxKernel.kernels.linux_testing;
         info = lib.importJSON ./bcachefs.json;
         version = "6.7.0-rc2";
     in kernel.override {
    argsOverride = {
      src = pkgs.fetchFromGitHub info;
      version = "${version}-bcachefs-unstable-${shorthash info.rev}";
      modDirVersion = version;
      structuredExtraConfig = with lib.kernel; {
        BCACHEFS_FS = option yes;
        BCACHEFS_QUOTA = option yes;
        BCACHEFS_POSIX_ACL = option yes;
        # useful for bug reports
        FTRACE = option yes;
        BCACHEFS_DEBUG_TRANSACTIONS = option no;
      };
    };
  }));
in
{
  #disabledModules = [ "tasks/filesystems/bcachefs.nix" ];
  imports = [
   #"${bcachefs-nixpkgs.path}/nixos/modules/tasks/filesystems/bcachefs.nix"
  ];

  boot.kernelPackages = lib.mkOverride 0 (customKernelPackages);

  # We need custom util-linux inside systemd to boot from UUID.

  # systemd.package = pkgs.systemdBcachefs;

  # compile bcachefs tools with pkgs from nixpkgs, not bcacehfs-nixpkgs.
  #
  nixpkgs.overlays = [
    (super: final: {
      bcachefs-tools = final.bcachefs-tools.overrideAttrs (attrs:
        let info = lib.importJSON ./bcachefs-tools.json;
        in rec {
          version = "git-${shorthash info.rev}";
          src = final.fetchFromGitHub info;
          cargoDeps = final.rustPlatform.importCargoLock {
            lockFile = "${src}/rust-src/Cargo.lock";
            outputHashes = {
              "bindgen-0.64.0" = "sha256-GNG8as33HLRYJGYe0nw6qBzq86aHiGonyynEM7gaEE4=";
            };
          };
      });
      # util-linuxMinimalBcachefs = overrideAllInputs final bcachefs-nixpkgs.util-linuxMinimal;
      # systemdBcachefs = super.systemd.override { util-linux = super.util-linuxMinimalBcachefs; };
      })
  ];
}
