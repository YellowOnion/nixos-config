{ config, pkgs, nix-gaming, unstable-nixpkgs, ... }:

let
  secrets = import ./secrets;
  audio_env = {
    LADSPA_PATH = "/run/current-system/sw/lib/ladspa";
  };
  libshoutSsl = pkgs.libshout.overrideAttrs (a : { propagatedBuildInputs = a.propagatedBuildInputs ++ [pkgs.openssl ]; });
in {
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.supportedFilesystems = [ "ntfs" ];
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      xdg-utils
      gnome.nautilus
      evince
      # basic sway stuff
      swaylock
      waybar
      sway-contrib.grimshot
      pulseaudio # pipewire is still heavily controlled via pulseaudio apps.
      grim
      slurp
      swayidle
      wl-clipboard
      brightnessctl
      dmenu
      xdotool
    ];
    extraSessionCommands = let
      gsettings = "${pkgs.glib}/bin/gsettings";
      schema = pkgs.gsettings-desktop-schemas;
      gschema = "org.gnome.desktop.interface";
    in ''
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
      export OBS_USE_EGL=1
      export XDG_DATA_DIRS=${schema}/share/gsettings-schemas/${schema.name}:$XDG_DATA_DIRS
      export GTK_USE_PORTAL=1
      ${gsettings} set ${gschema} icon-theme 'Papirus'
      ${gsettings} set ${gschema} gtk-theme 'Materia-Dark'
    '';
  };

  security.wrappers.sway = {
            owner = "root";
            group = "root";
            source = "${pkgs.sway}/bin/sway";
            capabilities = "cap_sys_nice+ep";
  };

  nixpkgs.overlays = [ (self: super : {
    sway-unwrapped = super.sway-unwrapped.overrideAttrs (attrs :{
      patches = attrs.patches ++ [ ./0001-Lower-CAP_SYS_NICE-from-ambient-set.patch ];
    });
  })];

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };

  programs.waybar.enable = true;

  #services.packagekit.enable = false;

  # Configure wacom tablet
  services.udev.packages = [ pkgs.libwacom ];
  services.xserver.wacom.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "dvorak";

  services.libinput.mouse.middleEmulation = false;
  services.ratbagd = {
    enable = true;
    package = let
      v = {  owner = "libratbag";
             repo = "libratbag";
             rev  = "1c9662043f4a11af26537e394bbd90e38994066a";
             hash = "sha256-IpN97PPn9p1y+cAh9qJAi5f4zzOlm6bjCxRrUTSXNqM=";};
    in pkgs.libratbag.overrideAttrs (a: {
      version = "unstable-git-${builtins.substring 0 7 (v.rev)}";
      src = pkgs.fetchFromGitHub v;
    });
  };

  hardware.bluetooth.enable = true;
  hardware.onlykey.enable = true;

  # Enable sound.
  hardware.pulseaudio.enable = false;
  systemd.user.services.pipewire.environment = audio_env;
  systemd.services.pipewire.environment = audio_env;
  services.pipewire = {
    enable = true;
    wireplumber = {
      enable = true;
    };
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraLv2Packages = with pkgs; [
      lsp-plugins
    ];
  };

  # help pulse audio use realtime scheduling
  security.rtkit.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # TODO, migrate to home-manager, not needed system wide.
    xsel
    alacritty

    keepassxc
    firefox
    discord

    mpv
    #anki-bin

    # These are needed system-wide for editing root files with doom emacs
    nil
    ripgrep
    fd
    nixfmt

    onlykey
    onlykey-cli

    (mpd.override {libshout = libshoutSsl;})
    cantata
    pavucontrol
    vlc
    spotify
    qjackctl

    signal-desktop

    papirus-icon-theme
    gnome.adwaita-icon-theme
    # Fails to build check in a few weeks
    #materia-theme

    libwacom
    krita
    xournalpp
    inkscape

    yquake2

    (nix-gaming.wine-ge) #.override { supportFlags.waylandSupport = false; })
    # nix-gaming.wine-discord-ipc-bridge
    heroic #.override { heroic-unwrapped = heroic-unwrapped.override { electron = electron_24 ;};})

    rnnoise-plugin
    lsp-plugins
    # TODO move to home manager
    (pkgs.writeShellScriptBin "runWithDiscordBridge" ''
      export PROTON_REMOTE_DEBUG_CMD="${nix-gaming.wine-discord-ipc-bridge}/bin/winediscordipcbridge.exe"
      export PRESSURE_VESSEL_FILESYSTEMS_RW="/run/user/$UID/discord-ipc-0"
      "$@"
    '')
  ];
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  #programs.gamemode.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    fira-code
    corefonts
    vistafonts
    (nerdfonts.override { fonts = [ "Monoid" "FiraCode" "CascadiaCode" "NerdFontsSymbolsOnly" ]; })
    (google-fonts.override { fonts = [ "Kode Mono" "EB Garamond" "Titillium Web" "Cutive Mono" "Orbit" "Varela Round" "Zilla Slab" ]; })
  ];

  environment.variables = { OBS_USE_EGL = "1"; };
}
