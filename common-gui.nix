{ config, pkgs, ... }:

let
  audio_env = {
    LADSPA_PATH = "/run/current-system/sw/lib/ladspa";
  };
  wlrVersion = "wlroots_0_19";
  overlay = self: super: {
    #sway-untouched = super.sway-unwrapped;

    scenefx = super.scenefx.override { wlroots_0_19 =  self."${wlrVersion}"; };
    swayfx-unwrapped = (super.swayfx-unwrapped.override { wlroots_0_19 = self."${wlrVersion}"; scenefx = self.scenefx; }).overrideAttrs (a: {
#      version = "${a.version}-deferred-cursor";
      patches = a.patches ++ [
      #  ./sway/0001-Deferred-cursor-support.patch
      ];
    });
    #sway-unwrapped = (super.sway-unwrapped.override { wlroots = self."${wlrVersion}"; }).overrideAttrs (a: {
    #  version = "${a.version}-deferred-cursor";
    #  patches = a.patches ++ [
    #    ./sway/0001-Deferred-cursor-support.patch
    #  ];
    #});
    "${wlrVersion}" = super.${wlrVersion}.overrideAttrs (a: {
      version = "${a.version}-deferred-cursor";
      patches = a.patches ++ [
        # ./wlroots/0001-wlr_keyboard_group-fix-leak-of-wlr_keyboard_group-ke.patch
        # ./wlroots/0001-output-cursor-deferred-cursor-move.patch
        # ./wlroots/0002-Set-wlr_output_cursor.max_latency-from-wlr_cursor.patch
        # ./wlroots/0003-deferred-cursors-add-a-max_cursor_latency-for-output.patch
      ];
    });
  };
in {
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  nixpkgs.overlays = [ overlay ];
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      xdg-utils
      nautilus
      evince
      # basic sway stuff
      swaylock
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

  ## Why do I need this again???
  #security.wrappers.sway = {
  #          owner = "root";
  #          group = "root";
  #          source = "${pkgs.sway}/bin/sway";
  #          capabilities = "cap_sys_nice+ep";
  #};

#  nixpkgs.overlays = [ (self: super : {
#    sway-unwrapped = super.sway-unwrapped.overrideAttrs (attrs :{
#      patches = attrs.patches ++ [ ./0001-Lower-CAP_SYS_NICE-from-ambient-set.patch ];
#    });
#  })];

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };

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
  services.pulseaudio.enable = false;
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


  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];
  };
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm   -    -    -     -    ${pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [
        rocblas
        hipblas
        clr
      ];
    }}"
  ];

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
    nixfmt-rfc-style

    onlykey
    onlykey-cli

    mpd
    cantata
    pavucontrol
    vlc
    spotify
    qjackctl

    signal-desktop

    papirus-icon-theme
    adwaita-icon-theme
    # Fails to build check in a few weeks
    #materia-theme

    libwacom
    krita
    xournalpp
    inkscape

    yquake2

    heroic

    rnnoise-plugin
    lsp-plugins
    # TODO move to home manager
    # TODO is a windows package, figure out how to build/include on linux
    # (pkgs.writeShellScriptBin "runWithDiscordBridge" ''
    #  export PROTON_REMOTE_DEBUG_CMD="${wine-discord-ipc-bridge}/bin/winediscordipcbridge.exe"
    #  export PRESSURE_VESSEL_FILESYSTEMS_RW="/run/user/$UID/discord-ipc-0"
    #  "$@"
    #'')

    clinfo
    vulkan-tools
    glxinfo
  ];
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  #programs.gamemode.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    fira-code
    corefonts
    vistafonts
    monaspace
    commit-mono
    (let font = google-fonts.override { fonts = [ "Kode Mono" ] ; };
     in stdenv.mkDerivation {
      name = "KodeMono-nerd-font-patched";
      src = font;
      nativeBuildInputs = [ nerd-font-patcher ];
      buildPhase = ''
        find \( -name \*.ttf -o -name \*.otf \) -execdir nerd-font-patcher -c {} \;
      '';
      installPhase = "cp -a . $out";
    })
    (google-fonts.override {
      fonts = [ "EB Garamond"
                "Titillium Web"
                "Cutive Mono"
                "Orbit"
                "Varela Round"
                "Zilla Slab"
                "Montserrat"
                "IBM Plex Sans"
                "IBM Plex Mono"
              ];
    })
  ] ++ builtins.attrValues {
    inherit (pkgs.nerd-fonts)
      monoid
      fira-code
      caskaydia-cove
      symbols-only
      ;
  };
}
