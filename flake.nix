{
  description = "Woobilicious' NixOS configuration";
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    factorio-nixpkgs.url = "github:YellowOnion/nixpkgs/factorio-patch2";
    sway-nix.url = "github:YellowOnion/sway-nix/";
    nix-gaming.url = "github:fufexan/nix-gaming/";
    factorio-mods = { url = "github:YellowOnion/factorio-mods";
                      flake = false; };
    auth-server = { url = "github:YellowOnion/auth-server";
                    flake = false; };
    conduit = {
        url = "gitlab:famedly/conduit";
        inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    typed-systems = {
      url = "github:YellowOnion/nix-typed-systems";
      flake = false;
    };
  };
  outputs = {self, nixpkgs-stable, nixpkgs-unstable, auth-server, sway-nix, nix-gaming, typed-systems, ... }@inputs:
    let
      inherit (import typed-systems) genAttrsMapBy systems' id;

      systems = [
        { name = "Purple-Sunrise";
          modules = [ ./purple.nix  ./purple-hw.nix ./bcachefs.nix ];
          system = systems'.x86_64-linux;
        }
        { name = "Purple-Sunrise2";
          modules = [ ./purple.nix ./purple2-hw.nix ];
          system = systems'.x86_64-linux;
        }
        { name = "Selene";
          modules = [ ./selene.nix ];
          system = systems'.x86_64-linux;
          nixpkgs = nixpkgs-stable;
        }
        { name = "Kawasaki-Lemon";
          modules = [ ./laptop2.nix ];
          system = systems'.x86_64-linux;
        }
        {
          name = "NixOS-installer";
          modules = [ ./iso.nix ];
          system = systems'.x86_64-linux;
        }
      ];
      mkConfig = { nixpkgs ? nixpkgs-unstable, name, system, modules }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            # overlays = [ sway-nix.overlays.default ];
          };
          nix-gaming        = inputs.nix-gaming.packages.${system};
          factorio-nixpkgs  = (import inputs.factorio-nixpkgs {
            inherit system;
            config.allowUnfree = true;
          });
        in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit nix-gaming factorio-nixpkgs nixpkgs nixpkgs-unstable;
              inherit (inputs) factorio-mods;
              auth-server = pkgs.haskellPackages.callPackage auth-server {};
              conduit = inputs.conduit.packages.${system};
            };
            modules = modules ++ [
                        ({...}: {
                          networking.hostName = name;
                          nix.registry.nixpkgs.flake = nixpkgs;
                          nix.registry.nix-gaming.flake = inputs.nix-gaming;
                          nix.registry.self.flake = self;
                          #nixpkgs.overlays = [ sway-nix.overlays.default ];
                          nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
                        }) ];
          };
      in
        {
          nixosConfigurations = genAttrsMapBy (a: a.name) mkConfig systems id;
        };
}
