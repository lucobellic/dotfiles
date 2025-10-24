{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    ags
    astal.apps
    astal.astal3
    astal.astal4
    astal.auth
    astal.battery
    astal.bluetooth
    astal.cava
    astal.greet
    astal.gjs
    astal.hyprland
    astal.io
    astal.mpris
    astal.network
    astal.notifd
    astal.powerprofiles
    astal.river
    astal.source
    astal.tray
    astal.wireplumber
    go
    gobject-introspection
    gtk-layer-shell
    gtk3
    gtk4
    gtk4-layer-shell
  ];

  xdg.configFile.ags = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/config/ags";
    recursive = true;
  };
}
