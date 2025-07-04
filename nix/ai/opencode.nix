{ config, ... }:

{

  xdg.configFile.opencode.source = config.lib.file.mkOutOfStoreSymlink ../../config/opencode;

}
