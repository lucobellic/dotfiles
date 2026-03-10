{ ... }:
{
  imports = [
    ./nvidia.nix
    ./themes/theme.nix
    ./hypr/hypr.nix
    ./sddm-astronaut.nix
  ];

  programs.sddmAstronaut = {
    enable = true;
    embeddedTheme = "purple_leaves";
  };
}
