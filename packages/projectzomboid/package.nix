{
  lib,
  pkgs,
  autoPatchelfHook,
  makeWrapper,
  openjdk25,
  openjdk25_headless,
  isHeadless ? false,
  ...
}:

let
  # doesn't work so calling java directly.
  binname = "ProjectZomboid64";
  pkgname = "projectzomboid";
  pname = "ProjectZomboid";
 
  version = "42.20.3";

  neededLibraries = with pkgs; [
    libz
    icu
    udev
    dbus ] ++ lib.optionals (!isHeadless) [
    libGL
    libGLX
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
    libICE
    libsm
  ];

  ojdk = if isHeadless then openjdk25_headless else openjdk25;
  thisPkg_data =
    reqArgs:
    (pkgs.stdenvNoCC.mkDerivation {
      inherit version;
      pname = "${pname}-Data";

      src = pkgs.requireFile reqArgs;

      nativeBuildInputs = [
        pkgs.unzip
      ];

      unpackPhase = ''
        unzip -q $src || true
      '';

      installPhase = ''
        mkdir -p $out
        mv data/noarch/game/* $out/
      '';

      dontBuild = true;
      dontFixup = true;
    });
  thisPkg = thisPkg_data (lib.importJSON ./version.json);
in
pkgs.stdenv.mkDerivation {
  inherit version;
  pname = if (!isHeadless) then pname else "${pname}-headless";
  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  src = thisPkg;

  buildInputs = neededLibraries;

  passthru.gc-pins = [ thisPkg ];

  installPhase = ''
    mkdir -p $out/opt
    mkdir -p $out/bin

    cd ${thisPkg}/projectzomboid/
    find -path './jre64/*' -prune                       \
        -o -path './natives/android/*' -prune           \
        -o -type f                                      \
        -exec install -Dm 'ug=rw,o=r' {} $out/opt/{} \;

    mv $out/opt/natives $out/lib

    cd $out/lib

    find -type f -name '*.so'   \
        -exec chmod 'a+x' {} \;

${lib.optionalString (!isHeadless) ''
    patchelf                                \
          --add-needed libGL.so             \
          --add-needed libEGL.so.1          \
          --add-needed libpulse.so.0        \
          $out/lib/libPZXInitThreads64.so
''}
${lib.optionalString isHeadless ''
    find -type f -name '*.so'                   \
        -exec echo "patching: " {} \;           \
        -exec patchelf                          \
            --remove-needed libasound.so.2      \
            --remove-needed libICE.so.6         \
            --remove-needed libSM.so.6          \
            --remove-needed libX11.so.6         \
            --remove-needed libXext.so.6        \
            --remove-needed libXi.so.6          \
            --remove-needed libXrender.so.1     \
            --remove-needed libXtst.so.6 {} \;
''}

    mv "$out/opt/${binname}" $out/bin/
    chmod 'a+x' "$out/bin/${binname}"
    
    ln -s $out/lib/libfmod.so $out/lib/libfmod.so.14
    ln -s $out/lib/libfmodstudio.so $out/lib/libfmodstudio.so.14

    makeWrapper ${ojdk}/bin/java "$out/bin/${pkgname + lib.optionalString isHeadless "-server"}"    \
    ${lib.optionalString (!isHeadless) "--suffix LD_PRELOAD : \"$out/lib/libPZXInitThreads64.so:${ojdk}/lib/openjdk/lib/libjsig.so\""} \
                --add-flags "-Xms\''${PZ_JVM_XMS:=2048m} -Xmx\''${PZ_JVM_XMX:=3072m} -XX:+UseZGC"   \
                --add-flags "-Duser.home=\''${PZ_HOME:=\$HOME/.config/projectzomboid}"              \
                --add-flags "-cp \"./:./projectzomboid.jar\""                       \
                --add-flags "-Djava.awt.headless=true"                              \
                --add-flags "--enable-native-access=ALL-UNNAMED"                    \
                --add-flags "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED" \
                --add-flags "-Dzomboid.steam=\''${PZ_STEAM:=0} -Dzomboid.znetlog=1" \
                --add-flags "-Djava.library.path=./:$out/lib/"                      \
                --add-flag  "-XX:-OmitStackTraceInFastThrow"                        \
                --add-flag  "-Djava.security.egd=file:/dev/urandom"                 \
                --chdir $out/opt/                                                   \
                --add-flag  ${if isHeadless
                              then "zombie/network/GameServer"
                              else "zombie/gameStates/MainScreenState" }
  '';
}
