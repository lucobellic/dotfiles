{
  nixpkgs.overlays = [
    (import (
      builtins.fetchTarball {
        url = "https://github.com/oxalica/rust-overlay/archive/0a9de73.tar.gz";
        sha256 = "16cjvccscxn3xqxfph9d2k34qlyi3d7va5pdf6cwzasrkq933zmm";
      }
    ))
  ];
}
