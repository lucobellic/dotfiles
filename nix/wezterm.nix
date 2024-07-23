{ ... }:

{
  home.file.wezterm = {
    source = ../.config/wezterm;
    target = ".config/wezterm";
    recursive = true;
  };
}
