# Minimal bootstrap host to get GPG working.
# Does NOT import system-default (to avoid secrets loading before they are unlocked).
{ inputs, ... }:
{
  flake.modules.nixos."cricro-bootstrap" =
    { pkgs, config, ... }:
    {
      imports = [
        inputs.self.modules.generic.constants
        ./_hardware-bootstrap.nix
      ];

      programs.gnupg.agent.enable = true;

      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
      };
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "bootstrap";
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
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };

      time.hardwareClockInLocalTime = true;
      i18n.defaultLocale = "en_US.UTF-8";

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
      };

      programs.fish.enable = true;
      users.defaultUserShell = pkgs.fish;
      users.users.cricro = {
        isNormalUser = true;
        description = "";
        extraGroups = [
          "networkmanager"
          "wheel"
          "dialout"
          "cdrom"
          "docker"
        ];
        packages = [ ];
        initialHashedPassword = "$y$j9T$RazGk8052EF4mQC2UYWA5/$KBvZpKyhxrZoFzM13c7y6i./096sDAQZ1FO3qL.ecX.";
        openssh.authorizedKeys.keys = config.systemConstants.sshConfig.ownKeys;
      };

      security.rtkit.enable = true;

      system.stateVersion = "24.05";
    };
}
