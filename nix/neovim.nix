{ lib, pkgs, ... }:

{
  home.activation = {
    cloneRepo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$HOME/.config/nvim" ]; then
        ${pkgs.git}/bin/git clone https://github.com/lucobellic/nvim-config.git $HOME/.config/nvim
      fi
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    extraPython3Packages = ps: [
      ps.pynvim
    ];
    withNodeJs = true;
    withRuby = false;
  };

  home.sessionVariables.EDITOR = "nvim";
}
