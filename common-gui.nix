{ config, pkgs, ... }:

let
  secrets = import ./secrets;
  ##latest = import <nixpkgs-master> { config.allowUnfree = true; };
in

{

  imports = [
  #  ./nur.nix
  ];
    # Enable the GNOME 3 Desktop Environment.
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = false;
    };

    desktopManager = {
      gnome.enable = true;
    };
  };

  networking.networkmanager.enable = true;

  # Configure wacom tablet
  services.udev.packages = [ pkgs.libwacom ];
  services.xserver.wacom.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "us";
  services.xserver.xkbVariant = "dvorak";

  services.xserver.libinput.mouse.middleEmulation = false;

  hardware.bluetooth.enable = true;

  # Enable sound.
  sound.enable = true;
   hardware.pulseaudio.enable = false;
   /*
  hardware.pulseaudio.daemon.config = {
    flat-volumes = "no";
    default-sample-rate = "48000";
    default-sample-format = "float32le";
    remixing-produce-lfe = "no";
    remixing-consume-lfe = "no";
    #default-fragments = "3";
    #default-fragment-size-msec = "30";
    realtime-scheduling = "yes";
    resample-method = "soxr-hq";
  }; */
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    config.pipewire = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
      };
      "stream.properties" = {
        "resample.quality" = 10;
     };
    };
 };

  # help pulse audio use realtime scheduling
  security.rtkit.enable = true;

  nixpkgs.config.allowUnfree = true;

  # GCCEmacs FAST AS FUCK BOI
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];

  environment.systemPackages = with pkgs; [
    keepassxc
    firefox
    discord

    emacsGcc
    ripgrep # needed for doom emacs
    fd      # ditto
    nixfmt  # ..

    mpd
    cantata
    vlc

    element-desktop
    signal-desktop

    libwacom
    krita
    xournalpp

    gnomeExtensions.appindicator
    (gnomeExtensions.audio-output-switcher.overrideAttrs (old: {
      buildInputs = [jq moreutils];
      postPatch = ''
        jq '."shell-version" += ["41"] ' metadata.json | sponge metadata.json
      '';
    }))
    rnnoise-plugin
  ];
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  services.flatpak.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    fira-code
    corefonts
    vistafonts
    (nerdfonts.override {fonts = [ "FiraCode" "CascadiaCode" ];})
    ];

  nix = {
    binaryCaches = [
      "https://nix-community.cachix.org"
    ];
    binaryCachePublicKeys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
