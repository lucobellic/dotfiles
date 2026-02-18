{ ... }:
{
  imports = [
    ./nvidia.nix
    ./themes/theme.nix
    ./hypr/hypr.nix
    ./silent-sddm.nix
  ];

  programs.silentSDDM = {
    enable = true;
    theme = "default";
  };
}
