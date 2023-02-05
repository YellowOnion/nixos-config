{ lib, config, pkgs, ... }:

let secrets = import ./secrets;

in 

{  
  imports = [ ./cachix.nix ];

  # use bfq on all spinning disks
  # TODO: add rules for Sata SSDs (mq-deadline or "none")
#  services.udev.extraRules = ''
#  ACTION=="add|change", KERNEL=="[sv]d[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
#  '';
  
  # Use the systemd-boot EFI boot loader.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "hid_apple.fnmode=0"
  ];
  
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
    extraGroups = [ "wheel" "audio" "networkmanager" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ secrets.daniel.sshKey ];
    };
  users.users.kent = {
    isNormalUser = true;
    initialPassword = secrets.kent.initialPass;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ secrets.kent.sshKey ];
  };
  
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
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

    (aspellWithDicts (d: [d.en d.en-computers d.en-science]))

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

  systemd.network.networks."wired" =  {
    enable = true;
    name = "en*";
    DHCP = "yes";
    networkConfig = {
      IPv6PrivacyExtensions = "yes";
    };
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
  PerSourceMaxStartups 2
  PerSourceNetBlockSize 24:56
  TrustedUserCAKeys ${secrets.userCA}
    '';
  services.fail2ban = {
    enable = true;
    ignoreIP = [
        "127.0.0.0/8"
        "::1"
        "home.gluo.nz"
    ];
    jails.DEFAULT = lib.mkAfter ''
      bantime = 3mo
    '';
  };
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = lib.attrValues secrets.zt;

  /*
  system.autoUpgrade = {
    enable = true;
    dates = "Sun *-*-* 05:00:00";
    };
  */
  nix = {
    daemonCPUSchedPolicy = "idle";
    #daemonIOSchedPriority = 7;
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "@wheel" ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
 /* nix.gc = {
    automatic = true;
    dates = "Mon *-*-* 05:00:00";
    options = "--delete-older-than 14d";
  };
  
  nix.optimise = {
    automatic = true;
    dates = [ "Mon *-*-* 5:30:00" ];
  }; */
  
}
