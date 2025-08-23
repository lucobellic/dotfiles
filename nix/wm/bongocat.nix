{ pkgs, lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "wayland-bongocat";
  version = "1.2.4";

  src = fetchFromGitHub {
    owner = "saatvik333";
    repo = "wayland-bongocat";
    rev = "v${version}";
    hash = "sha256-ek9sVzofW0sWJBCeudykdirDkF04YdR1gAcpeWqgQAQ=";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    wayland-scanner
    makeWrapper
  ];

  buildInputs = with pkgs; [
    wayland
    wayland-protocols
    libxkbcommon
  ];

  # Fix wayland-protocols path for the build
  preBuild = ''
    # Create protocols directory if it doesn't exist
    mkdir -p protocols
    
    # Set the path to wayland-protocols
    export PKG_CONFIG_PATH="${pkgs.wayland-protocols}/share/pkgconfig:$PKG_CONFIG_PATH"
    export WAYLAND_PROTOCOLS_DATADIR="${pkgs.wayland-protocols}/share/wayland-protocols"
    
    # Generate protocol files manually if needed
    if [ ! -f protocols/xdg-shell-client-protocol.h ]; then
      wayland-scanner client-header \
        ${pkgs.wayland-protocols}/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
        protocols/xdg-shell-client-protocol.h
    fi
    
    # Fix Makefile paths to use Nix store paths
    sed -i 's|/usr/share/wayland-protocols|${pkgs.wayland-protocols}/share/wayland-protocols|g' Makefile
  '';

  # Build phase
  buildPhase = ''
    runHook preBuild
    make
    runHook postBuild
  '';

  # Install phase
  installPhase = ''
    runHook preInstall
    
    # Create directories
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/doc/wayland-bongocat
    
    # Install binary
    cp build/bongocat $out/bin/
    
    # Create desktop entry
    cat > $out/share/applications/wayland-bongocat.desktop << EOF
[Desktop Entry]
Name=Wayland BongoCat
Comment=An adorable animated desktop overlay that reacts to keyboard input
Exec=$out/bin/bongocat --watch-config
Icon=input-keyboard
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=false
EOF
    
    # Install documentation
    cp README.md $out/share/doc/wayland-bongocat/
    if [ -f bongocat.conf ]; then
      cp bongocat.conf $out/share/doc/wayland-bongocat/bongocat.conf.example
    fi
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "An adorable animated desktop overlay that reacts to keyboard input for Wayland";
    longDescription = ''
      Wayland BongoCat is a delightful overlay that displays an animated bongo cat 
      reacting to your keyboard input. Perfect for streamers, content creators, 
      or anyone who wants to add some fun to their desktop.
      
      Features:
      - Real-time keyboard input detection
      - Configurable appearance and positioning
      - Hot-reload configuration support
      - Multiple monitor support
      - Wayland native with layer shell support
    '';
    homepage = "https://github.com/saatvik333/wayland-bongocat";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
