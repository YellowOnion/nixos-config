{ config, pkgs, ... }:

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
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };
  
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    pciutils
    wget
    screen
    vim
    htop
    rclone
    git
    git-crypt
    python
    syncthing
  ];
  
  services.openssh.enable = true;
  services.openssh.extraConfig = "TrustedUserCAKeys ${secrets.userCA}";
  
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ secrets.zt.wanabe ]; 
  
  
}
