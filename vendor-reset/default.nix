{ stdenv, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  name = "vendor-reset";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "gnif";
    repo  = "vendor-reset";
    rev   = "v${version}";
    sha256  = "04n5z338hw48v0skk23j4pmmzzk8ka0hb5qwvrwhjbp24x0aykh7";
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
