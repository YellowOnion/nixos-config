# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  factorio-nixpkgs,
  factorio-mods,
  auth-server,
  conduit,
  ...
}:
let
  icecastSSLPort = 8443;
  secrets = import ../secrets;

in
{
  #disabledModules = [ "services/games/factorio.nix" ];
  imports = [
    # Include the results of the hardware scan.
    ./selene-hw.nix
    ./common.nix
    ./common-server.nix
    #factorio-mods.nixosModules.default
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  networking.hostName = "Selene"; # Define your hostname.
  networking.domain = secrets.domain;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  # networking.useDHCP = true;
  # networking.interfaces.ens3.useDHCP = true;

  environment.systemPackages = [
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    #factorio-mods.overlays.default
  ];

  users.users.andrew = {
    isNormalUser = true;
    initialPassword = secrets.andrew.initialPass;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ secrets.andrew.sshKey ];
  };

  #  services.factorio = secrets.factorio // {
  #    enable = false;
  #    game-name = "Gluo NZ: Vanilla+" ;
  #    admins = [ "woobilicious" ];
  #    lan = true;
  #    mods = builtins.attrValues {
  #      inherit (factorio-mods.packages.${pkgs.system})
  #          # QOL
  #          "GUI_Unifyer"
  #          "BottleneckLite"
  #          "BetterAlertArrows"
  #          "calculator-ui"
  #          "ColorCodedPlanners"
  #          "CursorEnhancements"
  #          "even-distribution"
  #          "informatron"
  #          "ModuleInserter"
  #          "PipeVisualizer"
  #          "PlacementGuide"
  #          "QuickbarTemplates"
  #          "QuickItemSearch"
  #          "RateCalculator"
  #          "RecipeBook"
  #          "StatsGui"
  #          "Tapeline"
  #          "TaskList"
  #          "UltimateResearchQueue"
  #          "TintedGhosts"
  #          "VehicleSnap"
  #          "YARM"
  #          "pushbutton"
  #          "SantasNixieTubeDisplay"
  #          "Milestones"
  #          "helmod"
  #
  #          # gameplay addons
  #          "ArmouredBiters"
  #          "compaktcircuit"
  #          "equipment-gantry"
  #          "grappling-gun"
  #          "jetpack"
  #          "bobwarfare"
  #          "LogisticTrainNetwork"
  #          "rso-mod"
  #
  #          # costemics / flare
  #          "CleanedConcrete"
  #          "textplates"
  #          "DiscoScience"
  #          "DisplayPlates"
  #          "visual_tracers"
  #          "light-overhaul"
  #          "alien-biomes"
  #          "alien-biomes-hr-terrain"
  #      ;
  #    };
  #    mods-dat = ./mod-settings.dat ;
  #    requireUserVerification = false ;
  #  };

  #  services.matrix-conduit = {
  #    enable = true;
  #    package = conduit.default;
  #    settings.global = {
  #      server_name = "matrix.${config.networking.domain}";
  #      allow_registration = false;
  #    };
  #  };
  #
  #  services.heisenbridge = {
  #    enable = true;
  #    owner = secrets.matrix;
  #    homeserver = "http://[::1]:${toString config.services.matrix-conduit.settings.global.port}/";
  #  };

  services.stunnel =
    let
      CAdir = config.security.acme.certs."${config.networking.domain}".directory;
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

  services.icecast =
    let
      CADir = config.security.acme.certs."ice.${config.networking.domain}".directory;
    in
    {
      enable = true;
      listen.port = 64419;
      group = "nginx";
      hostname = "ice.${config.networking.domain}";
      admin = {
        password = secrets.icecast.password;
      };
      extraConf = ''
        <authentication>
          <source-password>${secrets.icecast.source-password}</source-password>
        </authentication>
        <listen-socket>
          <port>${toString icecastSSLPort}</port>
          <ssl>1</ssl>
        </listen-socket>
        <paths>
          <ssl-certificate>${CADir}/full.pem</ssl-certificate>
        </paths>
      '';
    };

  security.acme = {
    acceptTerms = true;
    defaults.email = secrets.email;
  };

  services.nginx =
    let
      proxySetHeaders = ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    in
    {
      enable = true;
      additionalModules = builtins.attrValues { inherit (pkgs.nginxModules) rtmp; };
      appendConfig = ''
        include /etc/nginx-rtmp/rtmp.conf;
      '';
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

      virtualHosts."${config.networking.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          root = "/var/www/";
        };
      };
      virtualHosts."owncast.${config.networking.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.owncast.port}/";
          proxyWebsockets = true;
          priority = 1150;
          extraConfig = proxySetHeaders;
        };
      };
      virtualHosts."matrix.${config.networking.domain}" = {
        forceSSL = true;
        enableACME = true;
        listen = [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
          {
            addr = "[::]";
            port = 443;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = 8448;
            ssl = true;
          }
          {
            addr = "[::]";
            port = 8448;
            ssl = true;
          }
        ];
        locations."/_matrix/" = {
          proxyPass = "http://[::1]:${toString config.services.matrix-conduit.settings.global.port}$request_uri";
          proxyWebsockets = true;
          priority = 1150;
          extraConfig = proxySetHeaders;
        };
      };
      virtualHosts."dead-suns.${config.networking.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:30000/";
          proxyWebsockets = true;
          priority = 1150;
          extraConfig = proxySetHeaders;
        };
      };
      virtualHosts."factorio.${config.networking.domain}" = {
        forceSSL = true;
        enableACME = true;
        #root = lib.strings.storeDir;
        #locations =
        #  let zipFile = lib.strings.removePrefix lib.strings.storeDir config.services.factorio.modsZipPackage;
        #  in {
        #    "=/ModPack" = {
        #      extraConfig = ''
        #      rewrite ^/ModPack$ ${zipFile} redirect;
        #      '';
        #    };
        #    "/" = { tryFiles = "${zipFile} =404"; };
        #};
      };
      virtualHosts."ice.${config.networking.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          return = "302 https://ice.${config.networking.domain}:${toString icecastSSLPort}$request_uri";
          priority = 1150;
        };
      };
      virtualHosts."share.${config.networking.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://purple-sunrise.tail31b4f8.ts.net:9999/";
          proxyWebsockets = true;
          priority = 1150;
          extraConfig = proxySetHeaders;
        };
      };
    };

  systemd.services.auth-server = {
    wantedBy = [ "multi-user.target" ];

    serviceConfig =
      let
        dir = "/var/lib/auth-server";
      in
      {
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
