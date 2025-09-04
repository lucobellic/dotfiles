{ pkgs, ... }:

{
  home.packages = [
    (pkgs.python3.withPackages (ps: with ps; [
      requests
      numpy
      pandas
      pyyaml
      typer
      scapy
    ]))
  ];
}
