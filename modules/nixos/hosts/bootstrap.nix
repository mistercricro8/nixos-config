{ inputs, ... }:
{
  flake.modules.nixos."hosts/bootstrap" =
    {
      config,
      pkgs,
      ...
    }:
    {
      systemConstants.configName = "bootstrap";

      imports = (with inputs.self.modules; [
        nixos."system/default"
        nixos."boot/minimal"
      ]);

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
          "nixremote"
        ];
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };

      time.hardwareClockInLocalTime = true;
      i18n.defaultLocale = "en_US.UTF-8";

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
