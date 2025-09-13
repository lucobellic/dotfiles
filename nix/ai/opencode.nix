{ config, pkgs, ... }:

{
  # home.packages = with pkgs; [
  #   opencode
  # ];

  home.sessionVariables = {
    OPENCODE_CONFIG = "~/.config/opencode/opencode.jsonc";
  };

  xdg.configFile.opencode.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/opencode;

}
