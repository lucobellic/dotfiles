{ ... }:

{

  xdg.configFile."starship.toml".source = ../.config/starship.toml;

  programs = {
    starship = {
      enable = true;
    };
  };
}
