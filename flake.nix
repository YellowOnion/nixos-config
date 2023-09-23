{
  description = "Woobilicious' NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    bcachefs-nixpkgs.url = "github:YellowOnion/nixpkgs/bump-bcachefs";
    factorio-nixpkgs.url = "github:YellowOnion/nixpkgs/factorio-patch2";
    sway-nix.url = "github:YellowOnion/sway-nix/";
    nix-gaming.url = "github:fufexan/nix-gaming/";
    factorio-mods = { url = "github:YellowOnion/factorio-mods";
                      flake = false; };
    auth-server = { url = "github:YellowOnion/auth-server";
                    flake = false; };
    conduit = {
        url = "gitlab:famedly/conduit";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {self, nixpkgs, auth-server, sway-nix, nix-gaming, ... }@inputs:
    let
      systems = [
        { name = "Purple-Sunrise";
          modules = [ ./purple.nix ];
          system = "x86_64-linux";
        }
        { name = "Selene";
          modules = [ ./selene.nix ];
          system = "x86_64-linux";
        }
      ];
      mkConfig = system: modules:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ sway-nix.overlays.default ];
          };
          nix-gaming   = inputs.nix-gaming.packages.${system};
          bcachefs-nixpkgs   = inputs.bcachefs-nixpkgs.legacyPackages.${system};
          factorio-nixpkgs = (import inputs.factorio-nixpkgs {
            inherit system;
            config.allowUnfree = true;
          });
        in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit nix-gaming factorio-nixpkgs bcachefs-nixpkgs;
              inherit (inputs) factorio-mods;
              auth-server = pkgs.haskellPackages.callPackage auth-server {};
              conduit = inputs.conduit.packages.${system};
            };
            modules = modules ++ [
                        ({...}: {
                          nix.registry.nixpkgs.flake = inputs.nixpkgs;
                          nix.registry.nix-gaming.flake = inputs.nix-gaming;
                          nixpkgs.overlays = [ sway-nix.overlays.default ];
                        }) ];
          };
      in
        {
          nixosConfigurations = nixpkgs.lib.foldr (a: b: b // { ${a.name} = mkConfig a.system a.modules; } ) {} systems;
        };
}
