{ pkgs, config, ... }:

let
  # Install caelestia-cli from source using fetchFromGitHub
  caelestia-cli = pkgs.callPackage
    (pkgs.fetchFromGitHub {
      owner = "caelestia-dots";
      repo = "cli";
      rev = "12f0d518622cbb9e00455c9591bd597f64a1747b";
      sha256 = "sha256-ZI+TIo/cnW18b5hPgCNBLNgujRV2ULfLAnit9TMzwA4=";
    })
    {
      rev = "12f0d518622cbb9e00455c9591bd597f64a1747b";
      caelestia-shell = null;
      withShell = false;
    };

  # Create beat_detector binary from caelestia-shell source
  beat_detector = pkgs.stdenv.mkDerivation {
    pname = "beat_detector";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "caelestia-dots";
      repo = "shell";
      rev = "main";
      sha256 = "sha256-iP1RWXkFA+WAbRNzc/IdGTVjv1l6N23gwv8IOoYoKwg=";
    };

    nativeBuildInputs = with pkgs; [ gcc ];
    buildInputs = with pkgs; [ aubio pipewire ];

    buildPhase = ''
      mkdir -p bin
      g++ -std=c++17 -Wall -Wextra \
        -I${pkgs.pipewire.dev}/include/pipewire-0.3 \
        -I${pkgs.pipewire.dev}/include/spa-0.2 \
        -I${pkgs.aubio}/include/aubio \
        assets/beat_detector.cpp \
        -o bin/beat_detector \
        -lpipewire-0.3 -laubio
    '';

    installPhase = ''
      install -Dm755 bin/beat_detector $out/bin/beat_detector
    '';
  };

  # Create a separate caelestia-shell script using nixGL-wrapped quickshell
  caelestia-shell = pkgs.writeShellScriptBin "caelestia-shell" ''
    export CAELESTIA_BD_PATH="${beat_detector}/bin/beat_detector"
    exec ${config.lib.nixGL.wrap pkgs.quickshell}/bin/quickshell -c caelestia "$@"
  '';
in
{
  home.packages = with pkgs; [

    # Core packages for caelestia
    ddcutil
    material-symbols

    caelestia-cli
    caelestia-shell
    beat_detector

    # Dependencies for caelestia-cli functionality
    libnotify
    swappy
    grim
    dart-sass
    app2unit
    wl-clipboard
    slurp
    wl-screenrec
    wf-recorder
    glib
    pulseaudio # libpulse is part of pulseaudio
    cliphist
    fuzzel

    # Dependencies for caelestia with quickshell and beat_detector
    inotify-tools
    aubio
    pipewire
    brightnessctl
    cava
    networkmanager
    lm_sensors
    libqalculate
  ];

  # Set environment variable for beat_detector path
  home.sessionVariables = {
    CAELESTIA_BD_PATH = "${beat_detector}/bin/beat_detector";
  };

  xdg.configFile.caelestia.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/caelestia;
}
