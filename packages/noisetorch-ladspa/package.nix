{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "noisetorch-ladspa";
  version = "unstable-57ce03bb";

  outputs = [
    "ladspa"
    "out"
  ];

  src = fetchFromGitHub {
    owner = "YellowOnion";
    repo  = "NoiseTorch";
    rev   = "57ce03bb549780632448824b8f75e84c7516fdc5";
    hash  = "sha256-8NxXmdM4m167mquM+D7j5hr1ChW+CRT8R/ymHQvxtg8=";
    fetchSubmodules = true;
  };
  sourceRoot = "${finalAttrs.src.name}/c/ladspa";

  buildPhase = ''
    make
  '';

  installPhase = ''
    install -D ./rnnoise_ladspa.so $ladspa/lib/ladspa/rnnoise_ladspa.so
    mkdir -p $out/lib/ladspa
    ln -s $ladspa/lib/ladspa/rnnoise_ladspa.so $out/lib/ladspa/
  '';

  meta = {
    description = "noisetorch's ladspa plugin";
    homepage = "https://github.com/noisetorch/NoiseTorch";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
