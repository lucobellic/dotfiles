{ pkgs, lib, ... }:

{
  imports = [
    ./cursor.nix
    ./fonts.nix
  ];

  home.packages = [
    pkgs.nwg-look
    pkgs.dracula-qt5-theme
    pkgs.dracula-theme
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct
  ];

  home.activation.cloneDraculaIcons = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.icons/dracula-icons" ]; then
      ${pkgs.git}/bin/git clone https://github.com/m4thewz/dracula-icons "$HOME/.icons/dracula-icons"
    fi
  '';

  gtk = {
    enable = true;
    colorScheme = "dark";
    theme.name = "Dracula";
    iconTheme.name = "dracula-icons";
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

}
