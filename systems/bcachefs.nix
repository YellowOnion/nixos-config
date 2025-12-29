{
  config,
  lib,
  pkgs,
  bcachefs-nixpkgs,
  ...
}:

let
  overrideAllInputs =
    final: p:
    p.override (
      lib.getAttrs (lib.attrNames (lib.filterAttrs (_: a: !a) p.override.__functionArgs)) final
    );
  shorthash = builtins.substring 0 7;
  customKernelPackages = (
    pkgs.linuxKernel.packagesFor (
      let
        kernel = pkgs.linuxKernel.kernels.linux_testing;
        info = lib.importJSON ./bcachefs.json;
        version = "6.10.0-rc4";
        versionSuffix = "-bcachefs-unstable-${shorthash info.rev}";
      in
      kernel.override {
        argsOverride = {
          src = pkgs.fetchFromGitHub info;
          version = version + versionSuffix;
          modDirVersion = version + versionSuffix;
          structuredExtraConfig = with lib.kernel; {
            LOCALVERSION = freeform versionSuffix;
            BCACHEFS_FS = module;
            BCACHEFS_QUOTA = option yes;
            BCACHEFS_POSIX_ACL = option yes;
            # useful for bug reports
            FTRACE = option yes;
            BCACHEFS_DEBUG_TRANSACTIONS = option yes;
            BCACHEFS_LOCK_TIME_STATS = yes;
          };
        };
      }
    )
  );
in
{
  boot.kernelPackages = lib.mkOverride 0 (pkgs.linuxPackages_latest);
  boot.kernelParams = [ "boot.shell_on_fail" ];
}
