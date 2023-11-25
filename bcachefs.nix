{ config, lib, pkgs, bcachefs-nixpkgs, ... }:

let
  overrideAllInputs = final: p: p.override (lib.getAttrs (lib.attrNames (lib.filterAttrs (_:a: !a) p.override.__functionArgs)) final);
  customKernelPackages = (pkgs.linuxKernel.packagesFor
    (let kernel = pkgs.linuxKernel.kernels.linux_testing;
         version = "6.7.0-rc2";
     in kernel.override {
    argsOverride = {
      src = pkgs.fetchFromGitHub {
        owner = "koverstreet";
        repo  = "bcachefs";
        rev   = "b8ddf059fd3adc4436d02d2f4b32717efb19d3cf";
        hash  = "sha256-bxdQLTbR4qF8k1Qgl4r5hGg0nWKvspQybyS0Hz21H4Y=";
      };
      version = "${version}-bcachefs-unstable-2023-11-23";
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
      # bcachefs-tools = overrideAllInputs final bcachefs-nixpkgs.bcachefs-tools;
      # util-linuxMinimalBcachefs = overrideAllInputs final bcachefs-nixpkgs.util-linuxMinimal;
      # systemdBcachefs = super.systemd.override { util-linux = super.util-linuxMinimalBcachefs; };
      })
  ];
}
