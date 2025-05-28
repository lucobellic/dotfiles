{ pkgs, ... }:

let
  # Define the source folder from the git repository
  hyprpanel = pkgs.fetchFromGitHub {
    owner = "Jas-SinghFSU";
    repo = "HyprPanel.git";
    rev = "4810d0f502b26469d96de2ea5310a7a84cd4696f";
    sha256 = "";
  };
in
{

  # libtomlplusplus-dev

  home.packages = with pkgs; [
    # hyprpanel and dependencies
    hyprpanel

    # Required dependencies
    # aylurs-gtk-shell-git
    # aylurs-gtk-shell
    # wireplumber
    # libgtop
    # bluez
    # bluez-utils
    # networkmanager
    # dart-sass
    # wl-clipboard
    # upower
    # gvfs
  ];

}
