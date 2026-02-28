{ config, ... }:

{
  home.sessionVariables = {
    OPENCODE_CONFIG = "~/.config/opencode/opencode.jsonc";
    OPENCODE_DISABLE_CLAUDE_CODE = "true";
    OPENCODE_ENABLE_EXA = "true";
    OPENCODE_SERVER_PORT = "4096";
    OPENCODE_SERVER_URL = "http://localhost:4096";
  };

  xdg.configFile.opencode.source = config.lib.file.mkOutOfStoreSymlink ~/.config/home-manager/config/opencode;

}
