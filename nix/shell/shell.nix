{ lib, pkgs, config, ... }:

{

  home.packages = [
    pkgs.ripgrep
    pkgs.yarn
    pkgs.grc
    pkgs.numbat
    pkgs.gh
    pkgs.yazi
  ];


  xdg.configFile.yazi.source = ../../config/yazi;
  home.file.".aider.conf.yml".source = config.lib.file.mkOutOfStoreSymlink ../../config/.aider.conf.yml;

  home.activation.customMessage = lib.mkAfter ''
    echo -e "\033[1;32m"
    echo -e "Perform github authentication:"
    echo -e "\tgh auth login --web -h github.com"
    echo -e "\tgh extension install github/gh-copilot --force"
    echo -e "\033[0m"
  '';

  imports = [
    ./fish.nix
    # ./ghostty.nix
    ./kitty.nix
    ./starship.nix
    ./wezterm.nix
    # ./zsh.nix
  ];

}
