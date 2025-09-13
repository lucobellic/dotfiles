# Dotfiles

## Bootstrap

### Nix

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### Home Manager

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl 
nix-channel --update
nix-shell '<home-manager>' -A install
```

#### Nvidia

Add `{ allowUnfree = true; }` to `~/.config/nixpkgs/config.nix`

### Setup

```sh
mv ~/.config/home-manager ~/.config/home-manager.bak
git clone https://github.com/lucobellic/dotfiles ~/.config/home-manager
cp ~/.config/home-manager/nix/users/lucobellic.nix ~/.config/home-manager/home.nix
home-manager switch
```
