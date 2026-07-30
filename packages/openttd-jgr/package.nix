{ lib, fetchFromGitHub, openttd, zstd, ... }:

openttd.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "openttd-jgrpp";
  version = "0.73.0";

  src = fetchFromGitHub {
    tag = "jgrpp-${finalAttrs.version}";
    owner = "JGRennison";
    repo  = "OpenTTD-patches";
    hash  = "sha256-eFUKJSpHLhyGXvKo/uSB01+5nGv5Y7yUTIU3U81Qx5U=";
  };

  buildInputs = prevAttrs.buildInputs ++ [ zstd ];
  patches = [];

  postInstall = ''
    mv $out/bin/openttd $out/bin/openttd-jgr
  '';

  meta.mainProgram = "openttd-jgr";
})
