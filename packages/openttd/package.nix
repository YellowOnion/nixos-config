{ pkgs ? import <nixpkgs> {}, ... }:
rec {
  jgr = pkgs.callPackage ./jgr.nix {};
  vanilla = pkgs.callPackage ./vanilla.nix {};
  launcher = with pkgs;
      (writeShellScriptBin "openttd-launcher"
        ''
        run_openttd () {
            cd "$1"
            exec ./bin/openttd
        }
        ${yad}/bin/yad --image ${vanilla}/share/icons/hicolor/128x128/apps/openttd.png \
               --text "Which Version of OpenTTD?" \
               --fixed \
               --buttons-layout=center \
               --button "Vanilla ${vanilla.version}:0" \
               --button "JGR patch-pack ${jgr.version}:1" \
        && run_openttd "${vanilla}" \
        || run_openttd "${jgr}"
        '');
}
