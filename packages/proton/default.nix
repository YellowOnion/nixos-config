{ lib, pkgs, ... }:

let
  protons = lib.concatMapAttrs (
    name: info:
    let
      nameLess = lib.removeSuffix ".tar.zst" name;
    in
    {
      ${nameLess} = (
        pkgs.stdenvNoCC.mkDerivation {
          name = nameLess;
          src = pkgs.fetchurl ({ inherit name; } // info);

          nativeBuildInputs = [ pkgs.zstd ];

          dontFixup = true;

          installPhase = ''
            mkdir -p $out
            mv * $out
          '';

        }
      );
    }
  ) (lib.importJSON ./versions.json);
in
protons
