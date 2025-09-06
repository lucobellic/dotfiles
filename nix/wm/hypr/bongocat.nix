{ config, pkgs, lib, ... }:

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

  find-keyboard-devices = pkgs.stdenv.mkDerivation {
    name = "find-keyboard-devices";
    src = null;
    phases = [ "installPhase" ];
    installPhase = ''
            mkdir -p $out/bin
            cat > $out/bin/find-keyboard-devices <<'EOF'
      #!/usr/bin/env bash
      grep -E 'Handlers|EV=' /proc/bus/input/devices | \
        grep -B1 'EV=120013' | \
        grep -Eo 'event[0-9]+' | \
        xargs -I{} echo /dev/input/{}
      EOF
            chmod +x $out/bin/find-keyboard-devices
    '';
    meta = {
      description = "Script to list all keyboard devices on /dev/input/event*";
      platforms = lib.platforms.linux;
    };
  };
in
{
  home.packages = [
    (config.lib.nixGL.wrap wayland-bongocat)
    find-keyboard-devices
  ];
  xdg.configFile.bongocat.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/bongocat;
}
