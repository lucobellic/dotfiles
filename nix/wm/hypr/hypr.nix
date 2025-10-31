{ config, pkgs, ... }:

{
  # hyprland
  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   package = config.lib.nixGL.wrap pkgs.hyprland;
  #   settings = { };
  #   extraConfig = ''source = ~/.config/home-manager/config/hypr/hyprland.conf'';
  # };

  # xdg.portal = {
  #   enable = true;
  #   extraPortals = with pkgs; [
  #     (config.lib.nixGL.wrap xdg-desktop-portal-gnome)
  #     (config.lib.nixGL.wrap xdg-desktop-portal-gtk)
  #   ];
  # };
  #
  # home.packages = with pkgs; [
  #   xwayland
  #   nvidia-vaapi-driver
  # ];

  # xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/hypr/hyprlock.conf;
  xdg.configFile.hypr.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/hypr;

  imports = [
    # ../quickshell.nix
    ./bongocat.nix
    ./hyde.nix
    ./ags.nix
    # ./caelestia.nix
    # ./end4.nix
  ];

  xdg.configFile.eww.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/eww;
  xdg.configFile.dunst.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/dunst;
  xdg.configFile.rofi.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/rofi;
  xdg.configFile.wlogout.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/wlogout;
  xdg.configFile.swaylock.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/swaylock;

}
