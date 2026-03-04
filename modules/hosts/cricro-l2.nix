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

      systemConstants.configName = "l2";
      sBoot.enable = true;
      sTailscale = {
        enable = true;
        hostName = "cricro-l2";
      };

      networking.hostName = "cricro-l2";

      time.timeZone = "America/Lima";

      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
      };

      system.stateVersion = "24.05";

      home-manager.users.cricro = {
        imports = with m; [
          homeManager."users/cricro"
          homeManager.cli-tools
          homeManager.semester
        ];

        home.stateVersion = "24.11";
        systemConstants.configName = "laptop";
      };

      home-manager.extraSpecialArgs = {
        inherit inputs;
      };
    };
}
