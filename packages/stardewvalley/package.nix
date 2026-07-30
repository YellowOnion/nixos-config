{
  config,
  lib,
  pkgs,
  gogextract,
  ...
}:

let
  binname = "Stardew Valley";
  pkgname = "stardewvalley";
  pname = "StardewValley";
 
  version = "1.6.15";

  neededLibraries = with pkgs; [
    libz
    libGL
    libGLX
    icu
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

  thisPkg_data =
    reqArgs:
    (pkgs.stdenvNoCC.mkDerivation {
      inherit version;
      pname = "${pname}-Data";

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
  thisPkg = thisPkg_data (lib.importJSON ./sdv.json);
in
pkgs.stdenv.mkDerivation {
  inherit version pname;
  nativeBuildInputs = [
    pkgs.autoPatchelfHook
  ];

  src = thisPkg;

  buildInputs = neededLibraries;

  passthru.gc-pins = [ thisPkg ];

  run = ''
    #!${pkgs.runtimeShell}
                                 
    STOREPATH=$(realpath $(dirname "$(realpath $0)")/../)
    STATEDIR="$HOME/.local/state/stardewvalley"

    mkdir -p "$STATEDIR"
    TMPDIR=$(${pkgs.mktemp}/bin/mktemp --directory)


    ${pkgs.bubblewrap}/bin/bwrap                                          \
        --bind / /                                                        \
        --overlay-src "$STOREPATH/opt"                                    \
        --overlay "$STATEDIR" "$TMPDIR" "$STATEDIR"                       \
        --chdir "$STATEDIR"                                               \
        --setenv LD_LIBRARY_PATH "${lib.makeLibraryPath neededLibraries}" \
        "$STATEDIR/${binname}" "$@"
  '';

  installPhase = ''
    mkdir -p $out/opt/
    mkdir -p $out/bin

    ln -s ${thisPkg}/* $out/opt/

    # we need to patch the binary for nixos compatibility.
    rm "$out/opt/${binname}"
    install "${thisPkg}/${binname}" "$out/opt/${binname}"

    ls -l "$out/opt/${binname}"

    echo -n "$run" > $out/bin/${pkgname}
    chmod +x $out/bin/${pkgname}
  '';

  
}
