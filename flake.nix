{
  description = "Woobilicious' NixOS configuration";
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    #factorio-nixpkgs.url = "github:YellowOnion/nixpkgs/factorio-patch2";
#    sway-nix = {
#      url = "github:YellowOnion/sway-nix";
#      inputs.nixpkgs.follows = "nixpkgs-unstable";
#    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    openttd = {
      url = "github:YellowOnion/nix-openttd-jgrpp";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    factorio-mods = { url = "github:YellowOnion/factorio-mods-nix"; };
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
  outputs = {self, nixpkgs-stable, nixpkgs-unstable, auth-server, typed-systems, home-manager, openttd, ... }@inputs:
    let
      inherit (import typed-systems) genAttrsMapBy systems' id;

      systems = import ./systems { inherit systems' nixpkgs-stable; };

      mkSystem = { nixpkgs ? nixpkgs-unstable, name, system, modules }:
        let
          factorioOverlay = self: super: { factorio = super.factorio.override ({ versionsJson = "${inputs.factorio-mods}/versions.json" ;}); };
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ factorioOverlay ];
          };
          factorio-nixpkgs  = (import inputs.factorio-nixpkgs {
            inherit system;
            config.allowUnfree = true;
          });
        in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit factorio-nixpkgs nixpkgs nixpkgs-unstable;
              inherit (inputs) factorio-mods;
              auth-server = pkgs.haskellPackages.callPackage auth-server {};
              conduit = inputs.conduit.packages.${system};
            };
            modules = modules ++ [
                        ({...}: {
                          networking.hostName = name;
                          nix.registry.nixpkgs.flake = nixpkgs;
                          nix.registry.self.flake = self;
                          nixpkgs.overlays = [ factorioOverlay ];
                          nixpkgs.config.allowUnfree = true;
                          nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
                        }) ];
          };

      hmConfigs = import ./home-manager { inherit systems'; };

      mkHmConfig = { nixpkgs ? nixpkgs-unstable, name, system, modules }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [];
          };
          in
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = { openttd = openttd.packages.${system}; };
              modules = modules;
            };
      in
        {
          nixosConfigurations = genAttrsMapBy (a: a.name) mkSystem systems id;
          homeConfigurations = genAttrsMapBy (a: a.name) mkHmConfig hmConfigs id;
        };
}
