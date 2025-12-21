{ pkgs, ... }:

let
  local_hyprland_path =
    "$HOME/Development/tools/hyprland-conan/install/Release";
in {
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
  services.ssh-agent.enable = true;

  home.packages = [ pkgs.curl ];

  home.sessionVariables = {
    PATH =
      "/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:${local_hyprland_path}:$PATH";
    OLLAMA_API_BASE = "http://127.0.0.1:11434";
    SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
  };

  imports = [
    ./ai/opencode.nix
    ./btop.nix
    ./dev/dev.nix
    ./dev/docker.nix
    ./dev/homer.nix
    ./git.nix
    ./neovim.nix
    ./nix.nix
    ./shell/shell.nix
    ./wm/wm.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
