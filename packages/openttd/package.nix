{ lib, oldScope, fetchurl, ... }:

oldScope.openttd.overrideAttrs (finalAttrs: oldAttrs: {
  pname = "openttd";
  version = "15.3";
  src = fetchurl {
    url = "https://cdn.openttd.org/openttd-releases/${finalAttrs.version}/${finalAttrs.pname}-${finalAttrs.version}-source.tar.xz";
    hash = "sha256-XqIe6n1Zx4pCBxkkrBjGvAEWCI8ulrFM/uk2kXWXO+c=";
  };
})
