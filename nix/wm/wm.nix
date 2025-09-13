{ pkgs, ... }:

{
  imports = [
    ./nixgl-nvidia.nix
    ./themes/theme.nix
    ./themes/fonts.nix
    ./hypr/hypr.nix
  ];
}
