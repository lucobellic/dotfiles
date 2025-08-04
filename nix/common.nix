{ pkgs, ... }:

{
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  targets.genericLinux.enable = true;

  programs.bash.enable = true;
  xdg.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      nixpkgs.config.hardware.opengl.enable = true;
    };
  };

  home.packages = [
    pkgs.curl
  ];

  home.sessionVariables = {
    OLLAMA_API_BASE = "http://127.0.0.1:11434";
  };

  imports = [
    ./ai/opencode.nix
    ./btop.nix
    ./git.nix
    ./neovim.nix
    ./nix.nix
    ./shell/shell.nix
    ./wm/hypr/hypr.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
