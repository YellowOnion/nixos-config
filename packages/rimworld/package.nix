{
  config,
  lib,
  pkgs,
  ...
}:

let
  version = "1.6.4633";

  neededLibraries = with pkgs; [
    libz
    libGL
    libGLX
    udev
    dbus
    libxkbcommon
    libx11
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxinerama
    libxrandr
    libxscrnsaver
    libxcb
    libxau
    libxxf86vm
    libpulseaudio
  ];

  gogextract = pkgs.stdenvNoCC.mkDerivation {
    pname = "gogextract";
    version = "6601b32";

    src = pkgs.fetchFromGitHub {
      owner = "Yepoleb";
      repo = "gogextract";
      rev = "6601b32feacecd18bc12f0a4c23a063c3545a095";
      hash = "sha256-BTtm3Tn2hFS512w+IcJQfGKSgi2dpYLg1VxNXRODBEI=";
    };

    buildInputs = [ pkgs.python3 ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share
      install  $src/gogextract.py $out/bin/gogextract
      
      cp $src/LICENSE $out/share/
    '';
  };

  rimworld-data =
    pname: reqArgs:
    (pkgs.stdenvNoCC.mkDerivation {
      inherit version;
      pname = "RimWorld_${pname}";

      src = pkgs.requireFile reqArgs;

      nativeBuildInputs = [
        gogextract
        pkgs.unzip
      ];

      unpackPhase = ''
        gogextract $src ./
        unzip -q ./data.zip
      '';

      installPhase = ''
        mkdir -p $out
        cp -r data/noarch/game/* $out
      '';

      dontBuild = true;
      dontFixup = true;
    });
  rimworld-core = rimworld-data "core" (lib.importJSON ./core.json);
  rimworld-anomaly = rimworld-data "anomaly" (lib.importJSON ./anomaly.json);
  rimworld-biotech = rimworld-data "biotech" (lib.importJSON ./biotech.json);
  rimworld-ideology = rimworld-data "ideology" (lib.importJSON ./ideology.json);
  rimworld-odyssey = rimworld-data "odyssey" (lib.importJSON ./odyssey.json);
  rimworld-royalty = rimworld-data "royalty" (lib.importJSON ./royalty.json);
in
pkgs.stdenv.mkDerivation {
  pname = "RimWorld";
  inherit version;
  nativeBuildInputs = [
    pkgs.autoPatchelfHook
  ];

  src = rimworld-core;

  buildInputs = neededLibraries;

  run = ''
    #!${pkgs.runtimeShell}
                                 
    STOREPATH=$(realpath $(dirname "$(realpath $0)")/../)
    STATEDIR="$HOME/.local/state/rimworld"

    mkdir -p "$STATEDIR"
    TMPDIR=$(${pkgs.mktemp}/bin/mktemp --directory)


    ${pkgs.bubblewrap}/bin/bwrap \
                                 --bind / / \
                                 --overlay-src "$STOREPATH/opt" \
                                 --overlay "$STATEDIR" "$TMPDIR" "$STATEDIR" \
                                 --chdir "$STATEDIR" \
                                 "$STATEDIR/RimWorldLinux" "$@"
  '';

  installPhase = ''
    mkdir -p $out/opt/Data
    mkdir -p $out/bin

    ln -s ${rimworld-core}/{RimWorldLinux_Data,Version.txt,Licenses.txt,ScenarioPreview.jpg} $out/opt/
    cp -p ${rimworld-core}/{RimWorldLinux,UnityPlayer.so}  $out/opt/
    chmod u+w $out/opt/{RimWorldLinux,UnityPlayer.so}
    ln -s ${rimworld-core}/Data/Core                        $out/opt/Data/Core
    ln -s ${rimworld-anomaly}/Data/Anomaly                  $out/opt/Data/Anomaly
    ln -s ${rimworld-biotech}/Data/Biotech                  $out/opt/Data/Biotech
    ln -s ${rimworld-ideology}/Data/Ideology                $out/opt/Data/Ideology
    ln -s ${rimworld-odyssey}/Data/Odyssey                  $out/opt/Data/Odyssey
    ln -s ${rimworld-royalty}/Data/Royalty                  $out/opt/Data/Royalty

    patchelf \
        --add-needed libz.so.1 \
        --add-needed libX11.so.6 \
        --add-needed libXau.so.6 \
        --add-needed libXcursor.so.1 \
        --add-needed libXdmcp.so.6 \
        --add-needed libXext.so.6 \
        --add-needed libXi.so.6 \
        --add-needed libXinerama.so.1 \
        --add-needed libXrandr.so.2 \
        --add-needed libXss.so.1 \
        --add-needed libXxf86vm.so.1 \
        --add-needed libxcb.so.1 \
        --add-needed libdbus-1.so.3 \
        --add-needed libudev.so.1 \
        --add-needed libxkbcommon.so.0 \
        --add-needed libGL.so.1 \
        --add-needed libpulse-simple.so.0 \
        $out/opt/UnityPlayer.so

    echo -n "$run" > $out/bin/rimworld
    chmod +x $out/bin/rimworld
  '';

  
}
