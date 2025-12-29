{
  description = "Woobilicious' NixOS configuration";
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    #    sway-nix = {
    #      url = "github:YellowOnion/sway-nix";
    #      inputs.nixpkgs.follows = "nixpkgs-unstable";
    #    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    arkenfox = {
      url = "github:arkenfox/user.js";
      flake = false;
    };

    openttd = {
      url = "github:YellowOnion/nix-openttd-jgrpp";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    factorio-mods = {
      url = "github:YellowOnion/factorio-mods-nix";
    };
    auth-server = {
      url = "github:YellowOnion/auth-server";
      flake = false;
    };
    conduit = {
      url = "gitlab:famedly/conduit";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    typed-systems = {
      url = "github:YellowOnion/nix-typed-systems";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      auth-server,
      typed-systems,
      home-manager,
      openttd,
      ...
    }@inputs:
    let
      inherit (import typed-systems) genAttrsMapBy systems' id;
      ottpkgs = openttd.packages;
      systems = import ./systems { inherit systems' nixpkgs-stable; };

      mkPrivPkgs =
        pkgs:
        import ./packages {
          inherit pkgs;
          lib = pkgs.lib;
        };

      mkNixpkgs =
        np: system:
        import np {
          inherit system;
          config.allowUnfree = true;
        };
      pkgs = mkNixpkgs nixpkgs-unstable systems'.x86_64-linux;
      privPkgs = mkPrivPkgs pkgs;

      mkSystem =
        {
          nixpkgs ? nixpkgs-unstable,
          name,
          system,
          modules,
        }:
        let
          pkgs = mkNixpkgs nixpkgs system;
          privPkgs = mkPrivPkgs pkgs;
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit nixpkgs nixpkgs-unstable privPkgs;
            inherit (inputs) factorio-mods;
            auth-server = pkgs.haskellPackages.callPackage auth-server { };
            conduit = inputs.conduit.packages.${system};
          };
          modules = modules ++ [
            (
              { ... }:
              {
                networking.hostName = name;
                nix.registry.nixpkgs.flake = nixpkgs;
                nix.registry.self.flake = self;
                nixpkgs.overlays = [ ];
                nixpkgs.config.allowUnfree = true;
                nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
                nix.channel.enable = false;
              }
            )
          ];
        };

      hmConfigs = import ./home-manager { inherit systems'; };

      mkHmConfig =
        {
          nixpkgs ? nixpkgs-unstable,
          name,
          system,
          modules,
        }:
        let
          pkgs = mkNixpkgs nixpkgs system;
          privPkgs = mkPrivPkgs pkgs;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit privPkgs;
            openttd = ottpkgs.${system};
            arkenfox = inputs.arkenfox;
          };
          modules = modules;
        };
    in
    {
      nixosConfigurations = genAttrsMapBy (a: a.name) mkSystem systems id;
      homeConfigurations = genAttrsMapBy (a: a.name) mkHmConfig hmConfigs id;
      packages.${systems'.x86_64-linux} = {
        openttd = ottpkgs.${systems'.x86_64-linux}.launcher;
      }
      // privPkgs;
      formatter.${systems'.x86_64-linux} = pkgs.nixfmt-rfc-style;
    };
}
