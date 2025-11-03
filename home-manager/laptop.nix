{ config, pkgs, ... }:

{
  imports = [ ./common.nix ];

  xdg.configFile."sway/config.d/this"
    .text =
    ''
      exec_always eww open bar --id primary  --screen eDP-1 --arg showbattery="BAT1" --arg orientation=v
      exec swayidle -w                              \
          timeout 610 'swaylock -f -c 000000'       \
          timeout 600 'swaymsg "output * dpms off"' \
          resume 'swaymsg "output * dpms on"'       \
          before-sleep 'swaylock -f -c 000000'

      set $dell "Dell Inc. DELL P2314H D59H247SAGRL"
      set $lg   "Goldstar Company Ltd LG ULTRAGEAR 203NTDV9B106"

      workspace 6 output $dell
      workspace 7 output $dell
      workspace 8 output $dell
      workspace 9 output $dell
      workspace 1 output $lg
      workspace 2 output $lg
      workspace 3 output $lg
      workspace 4 output $lg
      workspace 5 output $lg
      workspace 10 output $lg

      output $dell {
          transform 270
          pos 0 0
      }

      output $lg {
          pos 1080 0
          mode 2560x1440@180hz
      }
    '';
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
