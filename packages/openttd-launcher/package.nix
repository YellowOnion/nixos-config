{ lib, yad, openttd, openttd-jgr, writeShellApplication
,  ... }:

(writeShellApplication  {
  name = "openttd-launcher";
  excludeShellChecks = [ "SC2181" ];
  text = ''
    run_openttd () {
      cd "$1"
      exec ./bin/"$2"
    }

    ${yad}/bin/yad                                                     \
      --image  ${openttd}/share/icons/hicolor/128x128/apps/openttd.png \
      --text "Which Version of OpenTTD?"                               \
      --fixed                                                          \
      --buttons-layout=center                                          \
      --button "Vanilla ${openttd.version}:0"                          \
      --button "JGR patch-pack ${openttd-jgr.version}:1"

    if [[ $? == 0 ]]; then
         run_openttd "${openttd}" openttd \
    else
         run_openttd "${openttd-jgr}" openttd-jgr
    fi
  '';  
})
