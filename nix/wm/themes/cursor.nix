{ config, pkgs, ... }:
{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
    name = "bibata-cursors";
    package = pkgs.bibata-cursors;
    size = 12;
  };
}
