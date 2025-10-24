{ pkgs, config, lib, ... }:

let
  typelibs = lib.makeSearchPath "lib/girepository-1.0" (with pkgs; [
    gtk4
    libadwaita
    gtk4-layer-shell
    pango
    gdk-pixbuf
    graphene
    harfbuzz
    gobject-introspection
  ]);

in {
  home.packages = with pkgs; [
    (config.lib.nixGL.wrapOffload ags)
    astal.apps
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
    gjs
    libadwaita
    graphene
    graphene.dev
    gtk4
    gtk4.dev
    gtk4-layer-shell
    pango
    pango.dev
    gdk-pixbuf
    gdk-pixbuf.dev
    harfbuzz
    harfbuzz.dev
    glib.dev
    gobject-introspection.dev
  ];

  home.sessionVariables = {
    GI_TYPELIB_PATH = "$HOME/.nix-profile/lib/girepository-1.0:${typelibs}";
  };

  xdg.configFile.ags = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/home-manager/config/ags";
    recursive = true;
  };

  # Note: AGS type generation must be run manually after updates
  # Run: cd ~/.config/ags && yes | npx -y @ts-for-gir/cli@4.0.0-beta.38 generate --girDirectories="$HOME/.nix-profile/share/gir-1.0" --outdir="@girs" Astal-4.0 AstalIO-0.1 AstalApps-0.1 AstalAuth-0.1 AstalBattery-0.1 AstalBluetooth-0.1 AstalCava-0.1 AstalGreet-0.1 AstalHyprland-0.1 AstalMpris-0.1 AstalNotifd-0.1 AstalPowerProfiles-0.1 AstalRiver-0.1 AstalTray-0.1 AstalWp-0.1
}
