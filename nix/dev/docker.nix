{ pkgs, ... }:

{
  home.packages = with pkgs; [
    docker
    docker-compose
  ];

  systemd.user.services = {
    portainer-compose = {
      Unit = {
        Description = "Portainer Docker Compose";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f %h/.config/home-manager/config/portainer/docker-compose.yml up";
        WorkingDirectory = "%h/.config/home-manager/config/portainer";
        Restart = "always";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    n8n-compose = {
      Unit = {
        Description = "n8n Docker Compose";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f %h/.config/home-manager/config/n8n/docker-compose.yml up";
        WorkingDirectory = "%h/.config/home-manager/config/n8n";
        Restart = "always";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
