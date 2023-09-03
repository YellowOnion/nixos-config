# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, factorio-nixpkgs, factorio-mods, auth-server, ... }:
let
  secrets = import ./secrets;
  fmods =
    let mods = (import "${factorio-mods}/mods.nix") ({
          inherit (factorio-nixpkgs.factorio-utils) filterMissing;
          inherit (lib) fix;
          factorioMod = (factorio-nixpkgs.factorio-utils.factorioMod "/fpd.json");
        });
    in builtins.attrValues
      { inherit (mods)
        AfraidOfTheDark
        even-distribution
        QuickItemSearch
        RateCalculator
        sonaxaton-research-queue
        StatsGui
        TaskList
      ;};
  # dstd = pkgs.callPackage ../../home/daniel/dev/nix-dstd/default.nix {};
in
{
  disabledModules = [ "services/games/factorio.nix" ];
  imports =
    [ # Include the results of the hardware scan.
      ./selene-hw.nix
      ./common.nix
      ./common-server.nix
      "${factorio-nixpkgs.path}/nixos/modules/services/games/factorio.nix"
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  networking.hostName = "Selene"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  # networking.useDHCP = true;
  # networking.interfaces.ens3.useDHCP = true;

  environment.systemPackages = [
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (self: super: {
      factorio-headless = super.factorio-headless.override ({ versionsJson = "${factorio-mods}/versions.json" ;});
      factorio-utils    = factorio-nixpkgs.factorio-utils;
    })
  ];

  services.factorio = secrets.factorio // {
    enable = true;
    game-name = "Gluo Factorio Server" ;
    admins = [ "woobilicious" ];
    lan = true;
    mods = fmods;
    mods-dat = ./mod-settings.dat ;
    requireUserVerification = false ;
  };

  users.users.andrew = {
    isNormalUser = true;
    initialPassword = secrets.andrew.initialPass;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ secrets.andrew.sshKey ];
  };

  # services.openssh.enable = true;
  services.stunnel =
    let
      CAdir = config.security.acme.certs."gluo.nz".directory;
    in
    {
    enable = true;
    user = "nginx";
    group = "nginx";
    servers.rtmps-relay = {
      accept = 1935;
      connect = 1936;
      cert = "${CAdir}/full.pem";
    };
    clients."yt-live" = {
      accept = "localhost:19350";
      connect = "a.rtmp.youtube.com:443";
    };
  };
  services.owncast = {
    enable = true;
    rtmp-port = 1937;
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "daniel@gluo.nz";
  };
  services.nginx = {
    enable = true;
    additionalModules = builtins.attrValues { inherit (pkgs.nginxModules) rtmp; };
    appendConfig = ''
                 include /etc/nginx-rtmp/rtmp.conf;
    '';
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "gluo.nz" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          root = "/var/www/";
        };
      };
      "owncast.gluo.nz" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
            proxyPass = "http://127.0.0.1:8080/";
            proxyWebsockets = true;
            priority = 1150;
            extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-Server $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
        };
    };
      "dead-suns.gluo.nz" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
            proxyPass = "http://127.0.0.1:30000/";
            proxyWebsockets = true;
            priority = 1150;
            extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-Server $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
        };
      };
      "factorio.gluo.nz" = {
        forceSSL = true;
        enableACME = true;
        root = lib.strings.storeDir;
        locations =
          let zipFile = lib.strings.removePrefix lib.strings.storeDir config.services.factorio.modsZipPackage;
          in {
            "=/ModPack" = {
              extraConfig = ''
              rewrite ^/ModPack$ ${zipFile} redirect;
              '';
            };
            "/" = { tryFiles = "${zipFile} =404"; };
        };
      };
    };
    appendHttpConfig = let
      lua-resty-core =  pkgs.fetchFromGitHub {
        owner = "openresty";
        repo = "lua-resty-core";
        rev = "c48e90a8fc9d974d8a6a369e031940cedf473789";
        sha256 = "obwyxHSot1Lb2c1dNqJor3inPou+UIBrqldbkNBCQQk=";
      };
      in
     # ''
     # lua_package_path "${lua-resty-core}/lib/?.lua;;";
     # init_by_lua_block {
     #   require "resty.core"
     #   collectgarbage("collect")
     # }
     ''
       include /etc/nginx-rtmp/http.conf;
     '';
  };

  systemd.services.auth-server = {
      wantedBy = [ "multi-user.target" ];

      serviceConfig = let dir = "/var/lib/auth-server"; in {
          User = "auth-server";
          Group = "auth-server";
          WorkingDirectory = dir;
          ExecStart = "${auth-server}/bin/auth-server";
          Restart = "on-failure";
          StateDirectory = dir;
      };
    };


  users.users.auth-server = {
    isSystemUser = true;
    group = "auth-server";
  };

  users.groups.auth-server = { };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

