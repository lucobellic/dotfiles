{ pkgs, ... }:

let
  # Install caelestia-cli from source using fetchFromGitHub
  caelestia-cli = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "caelestia-dots";
    repo = "cli";
    rev = "99142f11ad7bccf3bb51cedfe55013c9690dcc0e";
    sha256 = "sha256-yd2NIfjWgsOWZsiMDgBw/p3IUHz60xoCsDzmZUWrOc4=";
  }) {
    rev = "99142f11ad7bccf3bb51cedfe55013c9690dcc0e";
    caelestia-shell = null; # Set to null unless you want the shell component
  };
in
{
  home.packages = with pkgs; [
    ddcutil
    caelestia-cli

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
    pulseaudio  # libpulse is part of pulseaudio
    cliphist
    fuzzel
  ];
}
