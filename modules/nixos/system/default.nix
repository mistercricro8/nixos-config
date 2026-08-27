{ inputs, ... }:
{
  flake.modules.nixos."system/default" =
    {
      pkgs,
      ...
    }:
    {
      imports = (
        with inputs.self.modules;
        [
          nixos."system/nur"
          nixos."secrets/sops"
          nixos."system/vm-variant"
          nixos."users/nixremote"
          generic.constants
          generic.system-constants
          generic.dotfiles-options
          generic.user-options
        ]
      );

      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        (final: prev: {
          moonlight-qt = prev.moonlight-qt.override { ffmpeg = prev.ffmpeg_7; };
        })
      ];

      networking.networkmanager.enable = true;
      networking.nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      networking.networkmanager.dns = "systemd-resolved";
      services.resolved.enable = true;

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "cricro"
          "nixremote"
        ];
        substituters = [
          "https://hyprland.cachix.org"
          "https://cache.flox.dev"
          "https://nix-community.cachix.org"
        ];
        trusted-substituters = [
          "https://hyprland.cachix.org"
          "https://cache.flox.dev"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        auto-optimise-store = true;
      };
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      programs.fish.enable = true;
      users.defaultUserShell = pkgs.fish;

      programs.nix-ld.enable = true;

      i18n.defaultLocale = "en_US.UTF-8";

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
      };

      services.locate.enable = true;

      virtualisation.docker.enable = true;

      security.rtkit.enable = true;

      environment.systemPackages = with pkgs; [
        gparted
        docker-buildx
        cifs-utils
      ];
    };
}
