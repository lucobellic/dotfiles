{ pkgs, ... }:

{
  imports = [ ./cursor.nix ./fonts.nix ];

  gtk = {
    enable = true;
    colorScheme = "dark";
    # font = {
    #   name =
    #   package =
    # }
    iconTheme = {
      name = "Dracula";
      package = pkgs.dracula-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

}
