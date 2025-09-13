{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python3.withPackages
      (ps: with ps; [ requests numpy pandas pyyaml typer scapy ]))

    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    go
    gopls
    delve
  ];
}
