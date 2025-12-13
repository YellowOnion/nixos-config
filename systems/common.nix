{ lib, config, pkgs, ... }:

let
  secrets = import ../secrets;
  ms2ns = a: a * 1000 * 1000;

in {
  # use bfq on all spinning disks
  # TODO: add rules for Sata SSDs (mq-deadline or "none")
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="[sv]d[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="kyber", ATTR{queue/iosched/write_lat_nsec}="${
      toString (ms2ns 400)
    }", ATTR{queue/iosched/read_lat_nsec}="${toString (ms2ns 100)}"
    ACTION=="add|change", KERNEL=="[sv]d[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber", ATTR{queue/iosched/write_lat_nsec}="${
      toString (ms2ns 40)
    }", ATTR{queue/iosched/read_lat_nsec}="${toString (ms2ns 10)}"
  '';

  # Use the systemd-boot EFI boot loader.
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "hid_apple.fnmode=0" ];
    loader = {
      systemd-boot.enable = true;
      systemd-boot.memtest86.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
  # Set your time zone.
  time.timeZone = "Pacific/Auckland";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_NZ.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "dvorak";
  };

  users.defaultUserShell = pkgs.zsh;

  users.users.daniel = {
    isNormalUser = true;
    initialPassword = secrets.daniel.initialPass;
    extraGroups =
      [ "wheel" "audio" "networkmanager" "libvirtd" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ secrets.daniel.sshKey ];
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
    killall
    file
    schedtool
    nix-prefetch-github
    usbutils
    lsof
    smem
    sysstat
    wget
    gnupg

    direnv
    starship
    tmux
    gist
    home-manager

    cachix

    (aspellWithDicts (d: [ d.en d.en-computers d.en-science ]))

    screen
    weechat
    irssi
    vim
    htop
    rclone
    git
    age
    git-crypt
    syncthing
  ];

  systemd.network.enable = true;
  systemd.network.wait-online.timeout = 5;

  networking.useDHCP = false;
  systemd.network.networks."wired" = {
    enable = true;
    name = "en*";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = true;
      IPv6PrivacyExtensions = "yes";
    };
    linkConfig.RequiredForOnline = "routable";
  };

  programs.zsh = with pkgs; {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    promptInit = ''
      eval "$(${direnv}/bin/direnv hook zsh)"
      eval "$(${starship}/bin/starship init zsh)"
    '';
  };

  services.openssh.enable = true;
  services.openssh.extraConfig = ''
    TrustedUserCAKeys ${secrets.userCA}
  '';
  services.fail2ban = {
    enable = false;
    ignoreIP = [ "127.0.0.0/8" "::1" "home.gluo.nz" ];
    #    jails.DEFAULT = lib.mkAfter ''
    #      bantime = 3mo
    #    '';
  };

  services.tailscale.enable = true;

  #services.zerotierone.enable = true;
  #services.zerotierone.joinNetworks = lib.attrValues secrets.zt;

  services.journald.extraConfig = ''
    MaxRetentionSec=90day
  '';
  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 90d";
    };
    settings = {
      # generally we don't need more than one build running at once
      # can sometimes cause OOM when jobs demand too much memory
      max-jobs = 1;
      auto-optimise-store = true;
      trusted-users = [ "@wheel" ];
      substituters = [
        "https://yo-nur.cachix.org"
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
#        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "yo-nur.cachix.org-1:E/RHfQMAZ90mPhvsaqo/GrQ3M1xzXf5Ztt0o+1X3+Bs="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
