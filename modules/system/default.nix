# Baseline config for every host
{ inputs, ... }:
{
  flake.modules.nixos.system-default =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules; [
        nixos.nur
        nixos.sops
        nixos.vscode-server

        generic.constants
        generic.system-constants
      ];

      nixpkgs.config.allowUnfree = true; # TODO: attempt a rebuild without this as this is set in the flake anyway
      nixpkgs.overlays = [
        inputs.vscode-extensions.overlays.default
      ];

      sops.gnupg.sshKeyPaths = [ "/home/cricro/.ssh/id_rsa" ];

      networking.networkmanager.enable = true;

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "cricro"
        ];
        substituters = [
          "https://hyprland.cachix.org"
          "https://cache.flox.dev"
        ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
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
        docker-buildx # TODO: the docker option should come with this nowadays
        cifs-utils
      ];
    };
}
