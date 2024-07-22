{ ... }:

{
  home.file.wezterm = {
    source = ~/.dotfiles/wezterm;
    target = ".config/wezterm";
    recursive = true;
  };
}
