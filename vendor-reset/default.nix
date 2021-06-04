{ stdenv, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  name = "vendor-reset";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "gnif";
    repo  = "vendor-reset";
    rev   = "225a49a40941e350899e456366265cf82b87ad25";
    sha256  = "071zd8slra0iqsvzqpp6lcvg5dql5hkn161gh9aq34wix7pwzbn5";
  };
  
  sourceRoot = "source";
  
  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;
  
  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];
 
  meta = {
  homepage = "https://github.com/gnif/vendor-reset";
  };
  
}     
