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
    schedtool
    nix-prefetch-github
    usbutils

    direnv
    starship
    cachix

    aspell

    wget
    screen
    vim
    htop
    rclone
    git
    age
    git-crypt
    syncthing
    steam-run
  ];


  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
  };

  services.openssh.enable = true;
  services.openssh.extraConfig = "TrustedUserCAKeys ${secrets.userCA}";
  
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = lib.attrValues secrets.zt;

  /*
  system.autoUpgrade = {
    enable = true;
    dates = "Sun *-*-* 05:00:00";
    };
  */
  nix = {
    autoOptimiseStore = true;
    daemonCPUSchedPolicy = "idle";
    #daemonIOSchedPriority = 7;
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
