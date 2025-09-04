{ config,pkgs, lib, ... }:

let
  wayland-bongocat = pkgs.stdenv.mkDerivation rec {
    pname = "wayland-bongocat";
    version = "1.2.5";
    src = pkgs.fetchFromGitHub {
      owner = "saatvik333";
      repo = "wayland-bongocat";
      rev = "v${version}";
      sha256 = "sha256-VkBuqmen6s/LDFu84skQ3wOpIeURZ5e93lvAiEdny70=";
    };

    nativeBuildInputs = with pkgs; [ pkg-config wayland-scanner ];
    buildInputs = with pkgs; [ wayland wayland-protocols ];
    makeFlags = [ "PREFIX=$(out)" ];
    preBuild = ''
      export WAYLAND_PROTOCOLS=${pkgs.wayland-protocols}/share/wayland-protocols
    '';

    postPatch = ''
      substituteInPlace Makefile \
        --replace '/usr/share/wayland-protocols' '${pkgs.wayland-protocols}/share/wayland-protocols'
    '';

    installPhase = ''
      mkdir -p $out/bin
      if [ -f build/bongocat ]; then
        cp build/bongocat $out/bin/
      elif [ -f bongocat ]; then
        cp bongocat $out/bin/
      fi
    '';

    meta = {
      description = "Wayland overlay that displays an animated bongo cat reacting to keyboard input";
      homepage = "https://github.com/saatvik333/wayland-bongocat";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  };

in
{
  home.packages = [ wayland-bongocat ];
  xdg.configFile.bongocat.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/bongocat;
}
