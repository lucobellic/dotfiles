{ pkgs, ... }:

{

  home.packages = [
    pkgs.ripgrep
    pkgs.yarn
    pkgs.grc
    pkgs.numbat
  ];

  imports = [
    ./kitty.nix
    ./wezterm.nix
    ./zsh.nix
    ./fish.nix
    ./starship.nix
  ];

}
