{ pkgs, ... }:

let
  # Define the source folder from the git repository
  hyprpanel = pkgs.fetchFromGitHub {
    owner = "Jas-SinghFSU";
    repo = "HyprPanel.git";
    rev = "commit-or-branch";
    sha256 = "sha256-hash-of-the-repo";
  };
in
{

  home.packages = with pkgs; [
    # hyprpanel and dependencies
    hyprpanel

    # aylurs-gtk-shell
    bightnessctl
    bluez
    bluez-utils
    bun
    dart-sass
    # gnome-bluetooth-3.0
    libgtop
    pipewire
    pywal
    wl-clipboard
  ];

}
