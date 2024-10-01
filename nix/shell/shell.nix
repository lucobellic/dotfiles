{ lib, pkgs, ... }:

{

  home.packages = [
    pkgs.ripgrep
    pkgs.yarn
    pkgs.grc
    pkgs.numbat
    pkgs.gh
    pkgs.yazi
  ];


  xdg.configFile.yazi.source = ../../.config/yazi;

  home.activation.customMessage = lib.mkAfter ''
    echo -e "\033[1;32m"
    echo -e "Perform github authentication:"
    echo -e "\tgh auth login --web -h github.com"
    echo -e "\tgh extension install github/gh-copilot --force"
    echo -e "\033[0m"
  '';

  imports = [
    ./kitty.nix
    ./wezterm.nix
    ./zsh.nix
    ./fish.nix
    ./starship.nix
  ];

}
