{
  description = "Woobilicious' NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nur-bcachefs.url = "github:YellowOnion/nur-bcachefs";
    bcachefs-nixpkgs.url = "github:YellowOnion/nixpkgs/bcachefs-fix";
    factorio-nixpkgs.url = "github:YellowOnion/nixpkgs/factorio-patch2";
    sway-nix.url = "github:YellowOnion/sway-nix/";
    nix-gaming.url = "github:fufexan/nix-gaming/";
    factorio-mods = { url = "github:YellowOnion/factorio-mods";
                      flake = false; };
    auth-server = { url = "github:YellowOnion/auth-server";
                    flake = false; };
  };
  outputs = {self, nixpkgs, nur-bcachefs, auth-server, sway-nix, nix-gaming, ... }@inputs:
    let
      systems = [
        { name = "Purple-Sunrise";
          module = ./purple.nix;
          system = "x86_64-linux";
        }
        { name = "Selene";
          module = ./selene.nix;
          system = "x86_64-linux";
        }
      ];
      mkConfig = system: module:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ sway-nix.overlays.default ];
          };
          nur-bcachefs = inputs.nur-bcachefs.packages.${system};
          nix-gaming   = inputs.nix-gaming.packages.${system};
          factorio-nixpkgs = (import inputs.factorio-nixpkgs {
            inherit system;
            config.allowUnfree = true;
          });
        in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit nix-gaming nur-bcachefs factorio-nixpkgs;
              inherit (inputs) factorio-mods;
              auth-server = pkgs.haskellPackages.callPackage auth-server {};
            };
            modules = [ module
                        ({...}: {
                          nix.registry.nixpkgs.flake = inputs.nixpkgs;
                          nix.registry.nix-gaming.flake = inputs.nix-gaming;
                          nixpkgs.overlays = [ sway-nix.overlays.default ];
                        }) ];
          };
      in
        {
          nixosConfigurations = nixpkgs.lib.foldr (a: b: b // { ${a.name} = mkConfig a.system a.module; } ) {} systems;
        };
}
