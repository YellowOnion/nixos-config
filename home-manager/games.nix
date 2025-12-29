{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.games;

  withExtraGameScripts =
    scripts:
    (pkgs.writeShellScriptBin "run.sh" ''
      ${
        let
          f = a: b: "exec ${a}/bin/run.sh " + b;
        in
        lib.foldr f ''"$@"'' scripts
      }
    '');

  gameEnv = ''
    export MANGOHUD_CONFIG=''${MANGOHUD_CONFIG:=gpu_temp,vram}
    export PIPEWIRE_NODE=''${PIPEWIRE_NODE:=input.game}
    export PULSE_SINK=''${PULSE_SINK:=input.game}
    export WINE_CPU_TOPOLOGY=''${WINE_CPU_TOPOLOGY:=6:12,13,14,15,16,17}
  '';
  gameScripts = withExtraGameScripts cfg.extraGameScripts;

  runVKGame = (
    pkgs.writeShellScriptBin "runVKGame" ''
      ${gameEnv}
      export OBS_VKCAPTURE=''${OBS_VKCAPTURE:=1}
      export MANGOHUD=''${MANGOHUD:=1}

      systemd-inhibit ${gameScripts}/bin/run.sh "$@"
    ''
  );

  runOGLGame = (
    pkgs.writeShellScriptBin "runOGLGame" ''
      ${gameEnv}

      systemd-inhibit ${pkgs.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture ${pkgs.mangohud}/bin/mangohud ${gameScripts}/bin/run.sh "$@"
    ''
  );

  runOGL32Game = (
    pkgs.writeShellScriptBin "runOGL32Game" (
      let
        pkgs32 = pkgs.pkgsi686Linux;
      in
      ''
        ${gameEnv}

        systemd-inhibit ${pkgs32.obs-studio-plugins.obs-vkcapture}/bin/obs-gamecapture ${pkgs32.mangohud}/bin/mangohud ${gameScripts}/bin/run.sh "$@"
      ''
    )
  );

  withSwayFloating = (
    pkgs.writeShellScriptBin "withSwayFloating" ''
      ID=$(base64 /dev/urandom | head -c 8)
      ( kill -SIGSTOP $BASHPID; exec "$@" ) &
      PID=$!
      [ -z "$GAME_NAME" ] && GAME_NAME=$ID
      swaymsg "for_window [ pid = $PID ] mark --replace \"game:$GAME_NAME\""
      kill -SIGCONT $PID
      wait $PID
    ''
  );
in
{
  options = {
    games = {
      extraGameScripts = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = lib.mdDoc "a list of extra scripts to run with a game";
      };
    };
  };
  config = lib.mkMerge [
    ({
      home.stateVersion = "24.05";
      home.packages = [
        pkgs.mangohud
        pkgs.obs-studio-plugins.obs-vkcapture
        pkgs.jq
        runVKGame
        runOGLGame
        runOGL32Game
        withSwayFloating
      ];
      xdg.dataFile = {
        "vulkan/explicit_layer.d/".source = (
          pkgs.symlinkJoin {
            name = "explicit_layers";
            paths = [
              "${pkgs.mangohud}/share/vulkan/implicit_layer.d/"
              "${pkgs.obs-studio-plugins.obs-vkcapture}/share/vulkan/implicit_layer.d/"
              ./steam-layers
              #(pkgs.runCommand "steam-overlay" {} ''
              #ln -s ../implicit_layer.d/steamoverlay_i386.json steamoverlay_i386.json
              #ln -s ../implicit_layer.d/steamoverlay_x86_64.json steamoverlay_x86_64.json
              #'')
            ];
          }
        );
      };
    })
  ];
}
# PROTON_LOG=1  VK_LOADER_DEBUG=layer VK_LOADER_LAYERS_ENABLE=VK_LAYER_MANGOHUD_overlay_64_x86_64,VK_LAYER_OBS_vkcapture_64,VK_LAYER_VALVE_steam_overlay_64 VK_INSTANCE_LAYERS=VK_LAYER_MANGOHUD_overlay_64_x86_64:VK_LAYER_OBS_vkcapture_64:VK_LAYER_VALVE_steam_overlay_64 %command%
