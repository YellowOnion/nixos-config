{ config, pkgs, ... }:

let
  secrets = import ./secrets;
  latest = import <nixpkgs-master> { config.allowUnfree = true; };
  gnome-hide-top-bar = pkgs.callPackage /home/daniel/dev/nix/gnome-hide-top-bar {} ;
in 

{
  imports = [
    ./nur.nix
  ];
    # Enable the GNOME 3 Desktop Environment.
  services.xserver = {
    enable = true;
  #    videoDrivers = ["amdgpu"];
    displayManager.gdm = {
      enable = true;
      wayland = false;
    };

    desktopManager.gnome.enable = true;
  };

  # Configure wacom tablet
  services.udev.packages = [ pkgs.libwacom ];
  services.xserver.wacom.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "us";
  services.xserver.xkbVariant = "dvorak";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.daemon.config = {
    flat-volumes = "no";
    default-sample-rate = "48000";
    default-sample-format = "float32le";
    remixing-produce-lfe = "no";
    remixing-consume-lfe = "no";
    default-fragments = "3";
    default-fragment-size-msec = "10";
    realtime-scheduling = "yes";
    resample-method = "soxr-hq";
   };
  # help pulse audio use realtime scheduling
  security.rtkit.enable = true;

  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    keepassxc
    firefox
    latest.discord
    emacs

    mpd
    cantata
    vlc

    element-desktop
    signal-desktop

    libwacom
    krita
    xournalpp

    gnomeExtensions.draw-on-your-screen
    gnome-hide-top-bar
    gnomeExtensions.appindicator
  ];
  programs.steam.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    corefonts
    vistafonts
    ];
}
