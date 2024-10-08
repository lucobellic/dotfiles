{ config, lib, pkgs, ... }:

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
    extraLuaPackages = ps: [
      ps.magick
    ];
    withNodeJs = true;
    withRuby = false;
  };

  xdg.configFile.neovide.source = config.lib.file.mkOutOfStoreSymlink ../.config/neovide;

  home.sessionVariables = {
    EDITOR = "nvim";
    NVIM_SERVER = "/tmp/neovim_server.pipe";
  };
}
