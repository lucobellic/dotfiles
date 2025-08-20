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
  
  # Create a separate caelestia-shell script using nixGL-wrapped quickshell
  caelestia-shell = pkgs.writeShellScriptBin "caelestia-shell" ''
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
  ];
}
