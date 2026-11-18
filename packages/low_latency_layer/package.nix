{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  vulkan-headers,
  vulkan-loader,
  vulkan-utility-libraries,
}:
stdenv.mkDerivation {
  pname = "low_latency_layer";
  version = "0.2.0";

  src = fetchFromGitHub (lib.importJSON ./version.json);

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    vulkan-utility-libraries
  ];

  meta = {
    description = "vendor agnostic nvidia reflex/amd antilag implementation";
    homepage = "https://github.com/Korthos-Software/low_latency_layer";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      YellowOnion
    ];
  };
}
