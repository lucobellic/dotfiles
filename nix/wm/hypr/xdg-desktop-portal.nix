{ config, pkgs, ... }: {

  # Install helper tools used by xdg-desktop-portal backends (OBS installed by distro)
  home.packages = with pkgs; [ slurp grim ];

  xdg.portal = {
    enable = true;
    extraPortals =
      [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];

    # Configure which portal to use for which interface
    config = {
      common = { default = [ "gtk" ]; };
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      };
    };

    # Enable XDG Desktop Portal for Hyprland
    xdgOpenUsePortal = true;
  };

  xdg.configFile."systemd/user.conf".source =
    config.lib.file.mkOutOfStoreSymlink
    ~/.config/home-manager/config/systemd/user.conf;

}

