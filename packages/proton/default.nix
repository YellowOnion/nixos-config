{ lib, pkgs, ... }:

let
  protons = lib.concatMapAttrs (
    name: info:
    let
      nameLess = lib.removeSuffix ".tar.gz" name;
    in
    {
      ${nameLess} = (
        pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
          name = nameLess;
          src = pkgs.fetchurl ({ inherit name; } // info);

          dontConfigure = true;
          dontBuild     = true;
          dontFixup     = true;

          outputs = [
            "out"
            "steamcompattool"
          ];

          installPhase = ''
            runHook preInstall

            echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

            mkdir $steamcompattool
            ln -s $src/* $steamcompattool
            rm $steamcompattool/compatibilitytool.vdf
            cp $src/compatibilitytool.vdf $steamcompattool

            runHook postInstall
          '';

        }));
    }
    ) (lib.importJSON ./versions.json);
in
protons
