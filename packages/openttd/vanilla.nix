{ lib, fetchFromGitHub, openttd, fetchurl, ... }:

openttd.overrideAttrs (oldAttrs: rec {
  pname = "openttd";
  version = "15.3";
  src = fetchurl {
    url = "https://cdn.openttd.org/openttd-releases/${version}/${pname}-${version}-source.tar.xz";
    sha256 = "1rrvjxsr2dp9zr6b35ifiw41c0dwqqcaq90r0x18misrgpm1x8jy";
  };
})
