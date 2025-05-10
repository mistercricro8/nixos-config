{ pkgs }:

with pkgs; [
    (catppuccin-sddm.override {
        flavor = "mocha";
        font = "CaskaydiaMono Nerd Font";
        fontSize = "12";
        background = ./config/backgrounds/shaded.png;
        loginBackground = true;
    })
    kitty
    v4l-utils
]