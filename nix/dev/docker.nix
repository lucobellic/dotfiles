{ pkgs, ... }:

{
  # 1. Install Docker and Docker Compose for the user
  home.packages = with pkgs; [
    docker
    docker-compose
  ];

  # 2. User systemd service to run Portainer CE via Docker Compose
  systemd.user.services.portainer-compose = {
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
}
