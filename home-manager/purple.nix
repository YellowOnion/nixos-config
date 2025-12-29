{ config, pkgs, privPkgs, ... }:

let
  setDefaultMonitor = (pkgs.writeShellScriptBin
    "setDefaultMonitor"
    ''
      ${pkgs.xorg.xrandr}/bin/xrandr --output $( ${pkgs.xorg.xrandr}/bin/xrandr --listmonitors | grep "2560.*1440" | awk "{ print \$4 ; }" ) --primary
    '');
  swayResume = (pkgs.writeShellScriptBin
  "swayResume"
      ''
        swaymsg 'output * dpms on'
        I=0
        while [[ $(${pkgs.xorg.xrandr}/bin/xrandr --listactivemonitors | head -1 | awk '{ print $2;}') != 2 || $I == 30 ]]; do
          sleep 1
          I=$(($I+1))
        done
        swaymsg 'output $lg mode 2560x1440@180hz'
        eww reload
        ${setDefaultMonitor}/bin/setDefaultMonitor
      '');
in
{
  imports = [ ./common.nix ];

  home.packages = with pkgs; [
    swayResume
    setDefaultMonitor
    zynaddsubfx
    # takes ages to compile, has bugs for some reason?
    #davinci-resolve
  ];

  games.extraGameScripts = [
    (pkgs.writeShellScriptBin "run.sh"
      ''
      ${setDefaultMonitor}/bin/setDefaultMonitor
      echo "egs ran!"
      exec "$@"
      ''
    )
  ];
  # Install proton versions
  xdg.dataFile =
    let v = { inherit (privPkgs.proton)
      GE-Proton10-27
      GE-Proton10-26
      GE-Proton10-25
      GE-Proton10-24
      ;};
    in
    pkgs.lib.concatMapAttrs (name: value: {
    "Steam/compatibilitytools.d/${name}".source = value;
  }) v;

  xdg.configFile."pipewire".source = ./pipewire.purple;

  xdg.configFile."sway/config.d/this"
    .text =
    ''
      exec ${setDefaultMonitor}/bin/setDefaultMonitor

      exec_always {
           eww kill
           eww open bar --id primary  --screen DP-1 --arg showbattery="" --arg orientation=v
           eww open bar --id secondary --screen DP-2 --arg showbattery="" --arg orientation=h
      }

      exec_always swayidle -w \
          timeout 630 'swaylock -f -c 000000' \
          timeout 600 'swaymsg "output * dpms off"' \
          resume ${swayResume}/bin/swayResume \
          before-sleep 'swaylock -f -c 000000'

      set $dell "Dell Inc. DELL P2314H D59H247SAGRL"
      set $lg   "LG Electronics LG ULTRAGEAR 203NTDV9B106"

      workspace 1 output $lg
      workspace 2 output $lg
      workspace 3 output $lg
      workspace 4 output $lg
      workspace 5 output $lg
      workspace 6 output $dell
      workspace 7 output $dell
      workspace 8 output $dell
      workspace 9 output $dell
      workspace 10:λ output $lg

      output $dell {
          transform 270
          pos 2560 0
      }

      output $lg {
          pos 0 0
          mode 2560x1440@180hz
      }

    input 1386:888:Wacom_Intuos_BT_M_Pen {
          map_to_output $lg
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
