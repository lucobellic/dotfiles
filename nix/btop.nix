{ ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "/usr/share/btop/themes/ayu.theme";
      theme_background = false;
      truecolor = true;
      force_tty = false;
    };
  };
}
