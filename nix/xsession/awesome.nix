{ pkgs, ... }:

{
  services.xserver.enable = true;

  xsession = {
    enable = true;
    windowManager = {
      awesome = {
        enable = true;
        luaModules = with pkgs.luaPackages; [
          luarocks
          luadbi-mysql # Database abstraction layer
        ];
      };
    };

  };

  imports = [
    ./picom.nix
  ];

}
