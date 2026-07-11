{
  lib,
  fetchFromGitHub,
  rustPlatform,
  cacert,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dufs";
  version = "v0.46.0";
 
  src = fetchFromGitHub {
    owner = "sigoden";
    repo = "dufs";
    tag = finalAttrs.version;
    hash = "sha256-Be7aJ5Bo5JSMcyyWsZ3ZamQ691TSIO4Ylxzil7UNJxk=";
  };
 
  cargoHash = "sha256-H2ew+sb60UnXe3Dls9MSKwAk4hT/yLSbgZz6pVOkHQQ=";

  buildInputs = [ cacert ];
  
  meta = {
    description = "Dufs is a distinctive utility file server that supports static serving, uploading, searching, accessing control, webdav";
    homepage = "https://github.com/sigoden/dufs";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
