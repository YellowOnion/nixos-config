# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,

  # non-common
  conduit,
  factorio-mods,
  foundryvtt,
  pkgs-unstable,
  privPkgs-unstable,
  ...
}:
let
  inherit (privPkgs-unstable) auth-server;
  icecastTLSPort = 8443;
  secrets = import ../secrets;
  cfg = config;
  domain = cfg.networking.domain;
  acmeCerts = name : file : cfg.security.acme.certs."${if name == "" then "" else "${name}."}${domain}".directory + "/${file}.pem";
in
{
  #disabledModules = [ "services/games/factorio.nix" ];
  imports = [
    ./selene-hw2.nix
    ./common.nix
    ./common-server.nix
    ./zfs.nix
    #factorio-mods.nixosModules.default
    foundryvtt.nixosModules.foundryvtt
  ];

  networking = {
    hostName = "Selene"; # Define your hostname.
    domain = secrets.domain;

    nftables.enable = true;
    firewall.allowedTCPPorts = [
      22 # hard code SSH for safety
      80 # HTTP
      443 # HTTPS
      1935 # rtmps
      icecastTLSPort
    ];
  # firewall.allowedUDPPorts = [ ... ];
  };
  services.tailscale.openFirewall = true;
  ## TODO BONDING
#  systemd.network = {
#    netdevs.bonded = {
#      netdevConfig = {
#        Kind = "bond";
#        Name = "bond0";
#      };
#      bondConfig = {
#        Mode = "";
#      };
#    };
#    networks = lib.mkForce {
#      "wired" = {
#        enable = true;
#        name  = "en*";
#        bond = "bond0";
#        dhcp = "yes";
#        networkConfig = {
#          IPvAcceptRA = false;
#        };
#      };
#    };
#  };
  
  boot.zfs.forceImportRoot = false;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  # networking.useDHCP = true;
  # networking.interfaces.ens3.useDHCP = true;

  environment.systemPackages = [
    auth-server
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    #factorio-mods.overlays.default
    (self: super: { owncast = pkgs-unstable.owncast ;})
    (self: super: {
      icecast = pkgs-unstable.icecast.overrideAttrs (oldAttrs: {
        patches = pkgs.fetchpatch {
          url = "https://gitlab.xiph.org/-/project/2/uploads/d2f8d747ee35cd1a3cd7b3f647d28c53/check-null.patch";
          hash = "sha256-mFezlxcT6G27jiR3ZAPNMPMMquUjKo8ZPIRfEz4jA54=";
        };
      });})
  ];

  # VTT management
  users.users.andrew = {
    isNormalUser = true;
    initialPassword = secrets.andrew.initialPass;
    extraGroups = [ "wheel" "vtt" ];
    openssh.authorizedKeys.keys = [ secrets.andrew.sshKey ];
  };

  users.users.daniel.extraGroups = [ "vtt" ];

  # the service is setup to wait till we're online,
  # but this fails for our secondary interface.
  systemd.network.wait-online.anyInterface = true;
  services.foundryvtt = {
    enable = true;
    hostName = "dead-suns.${domain}";
    world = "dead-suns";
    package = foundryvtt.packages.${pkgs.stdenv.hostPlatform.system}.foundryvtt_13;
    minifyStaticFiles = true;
    proxyPort = 443;
    proxySSL = true;
    upnp = false;
  };

  services.factorio = secrets.factorio // {
      enable = true;
      game-name = "Woobs Factory" ;
      admins = [ "woobilicious" ];
      package = pkgs.factorio-headless.override ({versionsJson = ./factorio-versions.json;});
      nonBlockingSaving = true;
      requireUserVerification = false;
      openFirewall = true;
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
  };

  #  services.matrix-conduit = {
  #    enable = true;
  #    package = conduit.default;
  #    settings.global = {
  #      server_name = "matrix.${domain}";
  #      allow_registration = false;
  #    };
  #  };
  #
  #  services.heisenbridge = {
  #    enable = true;
  #    owner = secrets.matrix;
  #    homeserver = "http://[::1]:${toString cfg.services.matrix-conduit.settings.global.port}/";
  #  };

  security.acme = {
    acceptTerms = true;
    defaults.email = secrets.email;
  };
  users.groups.acme = { };

  # TODO
  services.stunnel = {
    enable = true;
    user = "nginx";
    group = "acme";
    servers.rtmps-relay = {
      accept = ":::1935"; # IPv6
      connect = ":::1936";
      #connect = "/run/nginx/rtmp.sock"; doesn't work ;-(
      cert = acmeCerts "" "cert";
      key  = acmeCerts "" "key";
      };
#      clients."yt-live" = {
#        accept = "localhost:19350";
#        connect = "a.rtmp.youtube.com:443";
#      };
    };

  services.owncast = {
    enable = true;
    listen = "[::1]";
    # TODO STUNNEL
    rtmp-port = 1937;
    openFirewall = true;
  };

  services.murmur = {
    enable = true;
    tls = {
      certPath = acmeCerts "" "cert";
      keyPath = acmeCerts "" "key";
    };
    openFirewall = true;
  };

  systemd.services.murmur = {
    after = [ "acme-${domain}.service" ];
    serviceConfig.Group = lib.mkForce "acme";
  };

  security.acme.certs.${domain}.reloadServices = [ "murmur.service" ];


  services.icecast = {
      enable = true;
      listen.port = 64419;
      hostname = "ice.${domain}";
      admin = {
        password = secrets.icecast.password;
      };
      extraConfig = ''
        <authentication>
          <source-password>${secrets.icecast.source-password}</source-password>
        </authentication>
        <listen-socket>
          <port>${toString icecastTLSPort}</port>
          <tls>1</tls>
        </listen-socket>
        <paths>
          <tls-certificate>${acmeCerts "ice" "full"}</tls-certificate>
        </paths>
      '';
    };

  systemd.services.icecast.serviceConfig.Group = "acme";

  services.nginx = let
    authConfig = ''
    auth_request /auth;

    error_page 401 = @error401;
    location @error401 {
      return 302 https://auth.${domain}/login?returnTo=$scheme://$host$request_uri;
    }

    location = /auth {
      internal;
      proxy_pass              http://localhost:8081/auth;
      proxy_pass_request_body off;
      proxy_set_header        Content-Length "";
      proxy_set_header        X-Original-URI $request_uri;
    }
  ''; in {
    enable = true;
    additionalModules = builtins.attrValues { inherit (pkgs.nginxModules) rtmp zstd; };
    # secrets for upstream (i.e. YY/Twitch) are included
    # TODO stunnel
    appendConfig = ''
        include /etc/nginx-rtmp/rtmp.conf;
      '';

    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedBrotliSettings = true;
    recommendedProxySettings = true;

    # give Nginx access to our certs
    group = "acme";

    virtualHosts = {
      "${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          root = "/var/www/";
        };
      };
      
      "auth.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            return = "301 /login";
          };
          "/login" = {
            proxyPass = "http://[::1]:8081/login";
          };
        };
      };
      "owncast.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          # we force IPv6 to avoid connecting to v4 issues spamming logs
          proxyPass = "http://[::1]:${toString cfg.services.owncast.port}/";
          proxyWebsockets = true;
          priority = 1150;
        };
      };
      "matrix.${domain}" = {
        forceSSL = true;
        enableACME = true;
        # TODO firewall this properly
        listen = [
          { addr = "0.0.0.0";
            port = 443;
            ssl = true; }
          { addr = "[::]";
            port = 443;
            ssl = true; }
          { addr = "0.0.0.0";
            port = 8448;
            ssl = true; }
          { addr = "[::]";
            port = 8448;
            ssl = true; }
        ];
        locations."/_matrix/" = {
          proxyPass = "http://[::1]:${toString cfg.services.matrix-conduit.settings.global.port}$request_uri";
          proxyWebsockets = true;
          priority = 1150;
        };
      };

      "dead-suns.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://[::1]:${toString cfg.services.foundryvtt.port}/";
          proxyWebsockets = true;
          priority = 1150;
        };
      };

      "factorio.${domain}" = {
        forceSSL = true;
        enableACME = true;
        #root = lib.strings.storeDir;
        #locations =
        #  let zipFile = lib.strings.removePrefix lib.strings.storeDir cfg.services.factorio.modsZipPackage;
        #  in {
        #    "=/ModPack" = {
        #      extraConfig = ''
        #      rewrite ^/ModPack$ ${zipFile} redirect;
        #      '';
        #    };
        #    "/" = { tryFiles = "${zipFile} =404"; };
        #};
      };
      "ice.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          return = "302 https://ice.${domain}:${toString icecastTLSPort}$request_uri";
          priority = 1150;
        };
      };
      "share.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://purple-sunrise.tail31b4f8.ts.net:9999/";
          proxyWebsockets = true;
          priority = 1150;
        };
        extraConfig = authConfig;
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


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
