{ lib, stdenvNoCC, python3, fetchFromGitHub, ... }:
stdenvNoCC.mkDerivation {
    pname = "gogextract";
    version = "6601b32";

    src = fetchFromGitHub {
      owner = "Yepoleb";
      repo = "gogextract";
      rev = "6601b32feacecd18bc12f0a4c23a063c3545a095";
      hash = "sha256-BTtm3Tn2hFS512w+IcJQfGKSgi2dpYLg1VxNXRODBEI=";
    };

    buildInputs = [ python3 ];

    dontBuild = true;

    installPhase = ''
      install -D $src/gogextract.py $out/bin/gogextract
      install -D $src/LICENSE $out/share/LICENSE
    '';

    meta = {
      description = "Tool for extracting GoG-style self-extracting shell scripts (mojo setup)";
      homepage = "https://github.com/Yepoleb/gogextract";
      mainProgram = "gogextract";
      platforms = lib.platforms.all;
      license = lib.licenses.mit;
      maintainers = [ "YellowOnion" ];
    };
}
