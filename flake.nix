{
  description = "Woobilicious' NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    unstable-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bcachefs-nixpkgs.url = "github:YellowOnion/nixpkgs/bump-bcachefs";
    factorio-nixpkgs.url = "github:YellowOnion/nixpkgs/factorio-patch2";
    ryzen_smu-nixpkgs.url = "github:YellowOnion/nixpkgs/ryzen-smu";
    sway-nix.url = "github:YellowOnion/sway-nix/";
    nix-gaming.url = "github:fufexan/nix-gaming/";
    factorio-mods = { url = "github:YellowOnion/factorio-mods";
                      flake = false; };
    auth-server = { url = "github:YellowOnion/auth-server";
                    flake = false; };
    conduit = {
        url = "gitlab:famedly/conduit";
        # inputs.nixpkgs.follows = "nixpkgs";
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
        { name = "Kawasaki-Lemon";
          modules = [ ./laptop2.nix ];
          system = "x86_64-linux";
        }
        {
          name = "NixOS-installer";
          modules = [ ./iso.nix ];
          system = "x86_64-linux";
        }
      ];
      mkConfig = system: modules:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ sway-nix.overlays.default ];
          };
          nix-gaming        = inputs.nix-gaming.packages.${system};
          unstable-nixpkgs  = inputs.unstable-nixpkgs.legacyPackages.${system};
          bcachefs-nixpkgs  = inputs.bcachefs-nixpkgs.legacyPackages.${system};
          ryzen_smu-nixpkgs = inputs.ryzen_smu-nixpkgs.legacyPackages.${system};
          factorio-nixpkgs  = (import inputs.factorio-nixpkgs {
            inherit system;
            config.allowUnfree = true;
          });
        in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit nix-gaming factorio-nixpkgs bcachefs-nixpkgs ryzen_smu-nixpkgs unstable-nixpkgs;
              inherit (inputs) factorio-mods;
              auth-server = pkgs.haskellPackages.callPackage auth-server {};
              conduit = inputs.conduit.packages.${system};
            };
            modules = modules ++ [
                        ({...}: {
                          nix.registry.nixpkgs.flake = inputs.nixpkgs;
                          nix.registry.nix-gaming.flake = inputs.nix-gaming;
                          nix.registry.self.flake = self;
                          nixpkgs.overlays = [ sway-nix.overlays.default ];
                        }) ];
          };
      in
        {
          nixosConfigurations = nixpkgs.lib.foldr (a: b: b // { ${a.name} = mkConfig a.system a.modules; } ) {} systems;
        };
}
