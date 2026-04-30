{
  config,
  pkgs,
  openttd,
  arkenfox,
  ...
}:

let
  bgLockImg = pkgs.runCommand "bg_locked.png" { } ''
    export HOME=./
    mkdir tmp
    export TMP=./tmp
    ${pkgs.gmic}/bin/gmic ${./bg.png} blur 5 rgb2hsv split c "${./bg_noise.png}" mul[-2,-1] sub[-2] 10% add[-1] 10% append[-3--1] c hsv2rgb output[-1] "$out"
  '';
  lib = pkgs.lib;
in
{
  manual.manpages.enable = false;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.emacs = {
    enable = true;
    extraConfig = ''
    (load` "${./emacs.el}")
    '';
    package = pkgs.emacs-pgtk;
    extraPackages = p : with p; [
    company
    consult
    consult-lsp
    counsel
    doom-modeline
    doom-themes
    editorconfig
    eglot
    envrc
    evil
    evil-collection
    evil-surround
    evil-tutor
    flycheck
    flycheck-aspell
    flycheck-haskell
    general
    haskell-mode
    ivy
    ivy-rich
    ligature
    lsp-haskell
    lsp-ivy
    lsp-mode
    lsp-treemacs
    lsp-ui
    magit
    marginalia
    nix-mode
    orderless
    rainbow-delimiters
    rg
    smartparens
    tree-sitter
    treemacs
    treemacs-evil
    undo-fu
    undo-fu-session
    vertico
    ];
  };


  imports = [
    ./games.nix
  ];
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "daniel";
  home.homeDirectory = "/home/daniel";
  i18n.inputMethod = {
    # enabled = "fcitx5";
    #fcitx5.addons = [ pkgs.fcitx5-mozc ];
  };
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    xdg-utils
    nautilus
    file-roller
    evince
    swaylock
    swayidle
    sway-contrib.grimshot
    pulseaudio
    grim
    slurp
    
    wl-clipboard
    brightnessctl
    dmenu
    xdotool
    
    alacritty
    android-tools
    anki-bin
    pkgsRocm.blender
    cachix
    calibre
    cargo
    clinfo
    element-desktop
    eww
    ffmpeg-full
    (ghc.withPackages (
      p: with p; [
        hlint
        haskell-language-server
        stylish-haskell
        cabal-install
        linear
      ]
    ))
    hexchat
    imv
    libreoffice
    mesa-demos
    mumble
    nil
    nix-tree
    #openttd.launcher
    p7zip
    pureref
    qalculate-gtk
    renderdoc
    steamcmd
    unzip
    vulkan-tools
    # what's app
    wasistlos
    wlsunset
    wtype
    keepassxc

    # discord
    vesktop

    zellij
    mpv
    #anki-bin

    # add to flake dev shell
    nil
    ripgrep
    fd
    nixfmt

    libwacom
    krita
    xournalpp
    inkscape

    heroic

    mpd
    cantata
    pavucontrol
    vlc
    spotify
    qjackctl

    signal-desktop
    # obs-cmd
    (wrapOBS {
      plugins = [
        obs-studio-plugins.obs-vkcapture
        obs-studio-plugins.wlrobs
      ];
    })

    (writeShellScriptBin "discordToggleMute" ''
      xdotool key Control_R+backslash
    '')
    (wev.overrideAttrs (attrs: {
      src = fetchgit {
        rev = "2a46014ec5e375139f91aed456d5f01065964f86";
        url = "https://git.sr.ht/~sircmpwn/wev";
        hash = "sha256-0ZA44dMDuVYfplfutOfI2EdPNakE9KnOuRfk+CEDCRk=";
      };
    }))
    (pkgs.google-fonts.override {
      fonts = [
        "Kode Mono"
        "EB Garamond"
      ];
    })
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.swayfx;
    config = {};
    #extraConfig = lib.readFile ./sway.conf;
    checkConfig = true;
    wrapperFeatures.gtk = true;
    systemd.dbusImplementation = "broker";
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.common.default = [ "gtk" ];
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  gtk = {
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name    = "Papirus";
    };
    theme = {
      package = pkgs.gnome-themes-extra;
      name    = "Materia-Dark";
    };
  };
  
  home.pointerCursor = {
    x11.enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Original-Classic";
  };

  # include "${./emoji.compose}"

  home.file = {
    ".XCompose".text = ''
    include "${./dotXCompose}"
    include "${./maths.compose}"
  '';

    ".zshrc".source = ./.zshrc;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Daniel Hill";
      email = "daniel@gluo.nz";
      credential.helper = "store";
    };
  };

  programs.firefox = {
    enable = true;
    profiles."default" = {
      extraConfig = lib.readFile "${arkenfox}/user.js";
    };
  };

  xdg.configFile = { 
    "sway/config".source = lib.mkForce ./sway.conf;
    "sway/config.d/theme.conf".text = lib.readFile ./sway-theme.conf;
    "sway/config.d/home-manager".text = ''
      # TODO  $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
       seat seat0 xcursor_theme ${config.home.pointerCursor.name}
    '';

    "sway/config.d/bg_image".text = ''
      output * bg ${./bg.png} fill
    '';

    "swaylock/config".text = ''
      daemonize
      color=333333
      image=${./bg_lock.png}
    '';
  };
}
