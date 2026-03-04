# Home manager initialization
{ inputs, ... }:
{
  flake.modules.nixos.home-manager =
    { ... }:
    let
      gm = inputs.self.modules.generic;
    in
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        sharedModules = [
          gm.constants
          gm.system-constants
          inputs.self.modules.homeManager.catppuccin
        ];
      };
    };
}
