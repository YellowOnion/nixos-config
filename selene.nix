# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib,... }:
let
  secrets = import ./secrets;
  factorio-mods = builtins.fetchTarball "https://github.com/YellowOnion/factorio-mods/archive/master.tar.gz";
  factorio-nixpkgs-dir = builtins.fetchTarball "http://github.com/YellowOnion/nixpkgs/archive/factorio-patch.tar.gz";
  factorio-nixpkgs = import factorio-nixpkgs-dir { config.allowUnfree = true; };
  mods = (import "${factorio-mods}/mods.nix") ({
    inherit lib;
    inherit (secrets.factorio) username token;
    inherit (pkgs) fetchurl factorio-utils;
  });
  dstd = pkgs.callPackage ../../home/daniel/dev/nix-dstd/default.nix {};
in
{
  disabledModules = [ "services/games/factorio.nix" ];
  imports =
    [ # Include the results of the hardware scan.
      ./selene-hw.nix
      ./common.nix
      ./common-server.nix
      "${factorio-nixpkgs-dir}/nixos/modules/services/games/factorio.nix"
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
  networking.useDHCP = true;
  # networking.interfaces.ens3.useDHCP = true;

  environment.systemPackages = [
    dstd
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (self: super: {
      factorio-headless = factorio-nixpkgs.factorio-headless.override ({ versionsJson = "${factorio-mods}/versions.json" ;});
      factorio-utils    = factorio-nixpkgs.factorio-utils;
    })
  ];
  services.factorio = secrets.factorio // {
    enable = true;
    game-name = "Gluo Factorio Server" ;
    admins = [ "woobilicious" ];
    lan = true;
    mods = with mods; [
      AfraidOfTheDark
      even-distribution
      factoryplanner
      QuickItemSearch
      RateCalculator
      sonaxaton-research-queue
      StatsGui
      TaskList
    ];
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
  services.owncast.enable = true;
  security.acme = {
    acceptTerms = true;
    defaults.email = "daniel@gluo.nz";
  };
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    virtualHosts."owncast.gluo.nz" = {
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
    };
  };


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

