{ config, pkgs, ... }:

let
  secrets = import ./secrets;
  latest = import <nixpkgs-master> { config.allowUnfree = true; };
  vkc = import /home/daniel/dev/obs-vkcapture/default.nix {pkgs = pkgs;};
  nix-gaming = (import (builtins.fetchTarball {
      url = https://github.com/fufexan/nix-gaming/archive/master.tar.gz;
    })).packages.x86_64-linux;
in

{

  imports = [
  #  ./nur.nix
  ];

  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];

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

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      waybar
      sway-contrib.grimshot
      pulseaudio
      grim
      slurp
      swayidle
      wl-clipboard
      dmenu
    ];
    extraSessionCommands =
      let
        schema = pkgs.gsettings-desktop-schemas;
        gschema = "org.gnome.desktop.interface";
        in ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
      export OBS_USE_EGL=1
      export XDG_DATA_DIRS=${schema}/share/gsettings-schemas/${schema.name}:$XDG_DATA_DIRS
      gsettings set ${gschema} icon-theme 'Papirus'
      gsettings set ${gschema} cursor-theme 'Adwaita'
      gsettings set ${gschema} gtk-theme 'Materia-Dark'
    '';
  };
  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
      ];
      gtkUsePortal = true;
    };
  };


  programs.waybar.enable = true;

  #services.packagekit.enable = false;
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
  systemd.user.services.pipewire.environment.LADSPA_PATH = with pkgs; "/run/current-system/sw/lib/ladspa";
  systemd.services.pipewire.environment.LADSPA_PATH = with pkgs; "/run/current-system/sw/lib/ladspa";
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
    xsel
    alacritty

    keepassxc
    firefox
    latest.discord

    mpv
    anki-bin

    # emacsNativeComp
    emacsPgtkNativeComp
    ripgrep # needed for doom emacs
    fd      # ditto
    nixfmt  # ..

    mpd
    cantata
    vlc
    spotify
    qjackctl

    element-desktop-wayland
    signal-desktop

    papirus-icon-theme
    gnome.adwaita-icon-theme
    materia-theme

    libwacom
    krita
    xournalpp

    vkc.obs-vkcapture
    vkc.obs-vkcapture-lib32
    mangohud
    (wrapOBS { plugins = [ vkc.obs-vkcapture obs-studio-plugins.wlrobs]; } )

    # tkg
    nix-gaming.wine-tkg
    nix-gaming.wine-discord-ipc-bridge


    gnomeExtensions.appindicator
    (gnomeExtensions.audio-output-switcher.overrideAttrs (old: {
      buildInputs = [jq moreutils];
      postPatch = ''
        jq '."shell-version" += ["41"] ' metadata.json | sponge metadata.json
      '';
    }))
    rnnoise-plugin
    lsp-plugins
  ];
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  #services.flatpak.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    fira-code
    corefonts
    vistafonts
    (nerdfonts.override {fonts = [ "Monoid" "FiraCode" "CascadiaCode" ];})
    ];

  environment.variables = {
    PROTON_REMOTE_DEBUG_CMD="${nix-gaming.wine-discord-ipc-bridge}/bin/winediscordipcbridge.exe";
    PRESSURE_VESSEL_FILESYSTEMS_RW="/run/user/$UID/discord-ipc-0";
    OBS_USE_EGL="1";
  };
  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
 };
}
