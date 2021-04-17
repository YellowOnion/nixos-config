{config, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [ 
    cabal2nix
    nix-prefetch-git
    cabal-install
    haskellPackages.haskell-language-server
 ];
}

