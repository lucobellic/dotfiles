{
  inputs = {
    hyprpanel.url = "github:jas-singhfsu/hyprpanel";
    # If you're worried about mismatched versions
    # when using, e.g., `swww` from your own script,
    # you can also do the following.
    hyprpanel.inputs.nixpkgs.follows = "nixpkgs";
  };
}
