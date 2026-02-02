{ pkgs, ... }:
{
  home.packages = with pkgs; [
    banana-cursor
    bibata-cursors
    oreo-cursors-plus
    rose-pine-cursor
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
    name = "BreezeX-RosePineDawn-Linux"; # `~/.nix-profile/share/icons/`
    package = pkgs.rose-pine-cursor;
    size = 24;
  };
}
