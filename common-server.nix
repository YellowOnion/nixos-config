{ config, lib, pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    steam-run
  ];
}
