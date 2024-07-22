{ ... }:

{
  services.picom = {
    enable = true;
    backend = "glx";
    activeOpacity = 0.9;
    inactiveOpacity = 0.8;
    fade = true;
    fadeSteps = [ 0.07 0.07 ];
    settings = {
      glx = {
        no-stencil = true;
        copy_from-front = false;
        no-rebind-pixmap = true;
      };
      use-damage = false;
      inactive-dim = 0.15;
      blur = {
        method = "dual_kawase";
        size = 12;
        deviation = 5.0;
        background-frame = true;
        kern = "5x5box";
      };
    };
  };

}
