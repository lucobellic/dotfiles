{ config, pkgs, ... }:

{
  nixGL.packages = import <nixgl> { inherit pkgs; };
  nixGL.defaultWrapper = "mesa";
  nixGL.installScripts = [ "mesa" ];

  home.packages = with pkgs; [
    # Core Quickshell dependencies
    (config.lib.nixGL.wrap quickshell-git)

    # Hyprland ecosystem
    hyprland
    hypridle
    (config.lib.nixGL.wrap hyprlock)
    hyprpicker
    hyprsunset
    hyprutils
    xdg-desktop-portal-hyprland

    # Shell utilities
    easyeffects
    cliphist
    fuzzel
    wlogout
    translate-shell
    networkmanagerapplet # nm-connection-editor
    wl-clipboard

    # System utilities
    jq
    ripgrep
    curl
    rsync
    glib
    ddcutil

    # Illogical Impulse Qt Dependencies
    qt6.qt5compat
    qt6.full
    qt6ct
  ];


  home.sessionVariables = {
    LD_LIBRARY_PATH = "${pkgs.qt6.full}/lib:${pkgs.qt6.qt5compat}/lib:$LD_LIBRARY_PATH";
    QT_PLUGIN_PATH = "${pkgs.qt6.full}/lib/qt-6/plugins:${pkgs.qt6.qt5compat}/lib/qt-6/plugins";
    QML2_IMPORT_PATH = "${pkgs.qt6.full}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml";
  };

  home.sessionPath = [
    "${pkgs.qt6.full}/lib"
    "${pkgs.qt6.qt5compat}/lib"
  ];

  qt = {
    enable = true;
    platformTheme = {
      name = "gtk3";
    };
    style = {
      package = pkgs.adwaita-qt6;
      name = "adwaita-dark";
    };
  };

  xdg.configFile.hypr.source = config.lib.file.mkOutOfStoreSymlink ~/dots-hyprland/.config/hypr;
  xdg.configFile.quickshell.source = config.lib.file.mkOutOfStoreSymlink ~/dots-hyprland/.config/quickshell;
  xdg.configFile.qt5ct.source = config.lib.file.mkOutOfStoreSymlink ~/dots-hyprland/.config/qt5ct;
  xdg.configFile.qt6ct.source = config.lib.file.mkOutOfStoreSymlink ~/dots-hyprland/.config/qt6ct;

}
