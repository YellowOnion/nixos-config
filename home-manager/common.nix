{ config, pkgs, openttd, arkenfox, ... }:

let bgLockImg = pkgs.runCommand "bg_locked.png" {} ''
    export HOME=./
    mkdir tmp
    export TMP=./tmp
    ${pkgs.gmic}/bin/gmic ${./bg.png} blur 5 rgb2hsv split c "${./bg_noise.png}" mul[-2,-1] sub[-2] 10% add[-1] 10% append[-3--1] c hsv2rgb output[-1] "$out"
'';
    lib = pkgs.lib;
in
{
  manual.manpages.enable = false;
  # Let Home Manager install and manage itself.
  # programs.home-manager.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.emacs.enable = true;

  home.file.".doom.d".source = ./doom.d;

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
  home.packages = with pkgs;
    [
      (pkgs.google-fonts.override { fonts = [ "Kode Mono" "EB Garamond" ]; })
      wlsunset
      eww
      renderdoc
      blender-hip
      pureref
      wtype
      (wev.overrideAttrs
        (attrs: { src = fetchgit {
          rev = "2a46014ec5e375139f91aed456d5f01065964f86";
          url = "https://git.sr.ht/~sircmpwn/wev";
          hash = "sha256-0ZA44dMDuVYfplfutOfI2EdPNakE9KnOuRfk+CEDCRk=";
          };
      }))
      anki-bin
      android-tools
      element-desktop
      wasistlos
      mesa-demos
      clinfo
      vulkan-tools
      hexchat
      nil
      steamcmd
      rustc
      cargo
      cachix
      calibre
      ffmpeg-full
      imv
      unzip
      p7zip
      #musescore
      #muse-sounds-manager
      # obs-cmd
      (wrapOBS {
        plugins = [ obs-studio-plugins.obs-vkcapture obs-studio-plugins.wlrobs ];
      })
      (writeShellScriptBin "discordToggleMute"
        ''
          xdotool key Control_R+backslash
        '')
      openttd.launcher
    ];

  home.pointerCursor = {
    x11.enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Original-Classic";
  };

  home.file.".XCompose".text = ''
    include "${./dotXCompose}"
    include "${./emoji.compose}"
    include "${./maths.compose}"
  '';
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
    profiles."default" =
      { userChrome =
          ''#main-window[tabsintitlebar="true"]:not([extradragspace="true"]) #TabsToolbar > .toolbar-items {
              opacity: 0;
              pointer-events: none;
            }
            #main-window:not([tabsintitlebar="true"]) #TabsToolbar {
                visibility: collapse !important;
            }
          '';
        extraConfig = lib.readFile "${arkenfox}/user.js";
      };
  };
  #home.service.emacs = {
  #  enabled = true;
  #  package = doom-emacs; };
  xdg.configFile = {
    "tmux/tmux.conf".text = lib.readFile ./tmux.conf;
    "sway/config".text = lib.readFile ./sway.conf;
    "sway/config.d/theme.conf".text = lib.readFile ./sway-theme.conf;
    "sway/config.d/home-manager"
      .text = ''
           # TODO  $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
            seat seat0 xcursor_theme ${config.home.pointerCursor.name}
      '';

    "sway/config.d/bg_image"
      .text = ''
            output * bg ${./bg.png} fill
          '';

    "swaylock/config".text =
      ''
        daemonize
        color=333333
        image=${./bg_lock.png}
      '';
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";
}
