# Host: l2

{ inputs, ... }:
{
  flake.modules.nixos."cricro-l2" =
    { ... }:
    let
      m = inputs.self.modules;
    in
    {
      imports = with m; [
        nixos.system-server
        nixos.for-laptops
        nixos.catppuccin
        nixos.home-manager
        nixos."users/cricro"
        nixos.sBoot
        nixos.sTailscale
        ./_hardware-cricro-l2.nix
      ];

      # ============== Options imports config
      systemConstants.configName = "l2";
      sBoot.enable = true;
      sTailscale = {
        enable = true;
        hostName = "cricro-l2";
      };

      # ============== Networking
      networking.hostName = "cricro-l2";

      # ============== Time
      time.timeZone = "America/Lima";

      # ============== Extra
      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
      };

      # ============== System
      system.stateVersion = "24.05";

      # ============== Home manager
      home-manager.users.cricro = {
        imports = with m; [
          homeManager."users/cricro"
          homeManager.cli-tools
          homeManager.dotfiles
          homeManager.semester
        ];

        sDotfiles = {
          enable = true;
          configs = {
            bottom.enable = true;
            rofi.enable = true;
            yazi.enable = true;
            starship.enable = true;
          };
        };

        home.stateVersion = "24.11";
        systemConstants.configName = "laptop";
      };

      home-manager.extraSpecialArgs = {
        inherit inputs;
      };
    };
}
