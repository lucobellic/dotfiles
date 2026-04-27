# AGENTS.md

## Configuration

- This repository is a dotfiles/home-manager config; no standard build or test commands.
- Uses Home Manager with Nix flakes for configuration management
- User is on non-NixOS Linux; each user has a named `homeConfiguration` in `flake.nix`
- Per-user configs live in `nix/users/`; shared config lives in `nix/common.nix`
- For Nix config changes, apply with: `home-manager switch -b backup --show-trace --flake .#lhussonn`
