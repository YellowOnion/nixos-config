{
  lib,
  bitwig-studio6,
  requireFile,
  fetchurl,
  ...
}:
let
  replacementJar = requireFile {
    name = "bitwig-2ae8d953.jar";
    url  = "http://nothing.com/bitwig.jar";
    hash = "sha256-KujZU3h1/OluU8QxPR/QPlz2wS1j3lS5Wxj8zBvKWLQ=";
  };
  version = "6.0";
  src = fetchurl {
    name = "bitwig-studio-${version}.deb";
    url = "https://www.bitwig.com/dl/Bitwig%20Studio/${version}/installer_linux";
    hash = "sha256-jrCTgaxfeWhfKwLeKLmqTQWS7RVbVnHqJ0InCipmm8k=";
  };
in
(bitwig-studio6.overrideAttrs (attrs: {
  inherit version src;

  passthru.gc-pins = [ replacementJar ];

  postInstall = ''
    cd $out/libexec/bin/
    mv bitwig.jar bitwig.jar.backup
    cp ${replacementJar} ./bitwig.jar
  '';
}))
