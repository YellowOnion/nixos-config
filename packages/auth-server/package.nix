{ haskellPackages, ...}: (
  haskellPackages.callCabal2nix "auth-server" ./. {}
)
