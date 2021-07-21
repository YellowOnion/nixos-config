{ lib, config, pkgs, ... }:

let secrets = import ./secrets;

in 

{  
  # use bfq on all spinning disks
  # TODO: add rules for Sata SSDs (mq-deadline or "none")
  services.udev.extraRules = ''
  ACTION=="add|change", KERNEL=="[sv]d[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';
  
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
  
    users.users.daniel = {
    isNormalUser = true;
    initialPassword = secrets.daniel.initialPass;
    extraGroups = [ "wheel" "audio" ]; # Enable ‘sudo’ for the user.
  };
  
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    pciutils
    killall
    wget
    screen
    vim
    htop
    rclone
    git
    age
    git-crypt
    python
    syncthing
    steam-run
  ];
  
  services.openssh.enable = true;
  services.openssh.extraConfig = "TrustedUserCAKeys ${secrets.userCA}";
  
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = lib.attrValues secrets.zt;


  system.autoUpgrade = {
    enable = true;
    dates = "Sun *-*-* 05:00:00";
    };
  
  nix.gc = {
    automatic = true;
    dates = "Mon *-*-* 05:00:00";
    options = "--delete-older-than 14d";
  };
  
  nix.optimise = {
    automatic = true;
    dates = [ "Mon *-*-* 5:30:00" ];
  };
  
}
