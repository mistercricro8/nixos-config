# Home manager initialization. Uses stable branch.
{ inputs, ... }:
{
  flake.modules.nixos.home-manager-stable =
    { ... }:
    let
      gm = inputs.self.modules.generic;
    in
    {
      imports = [ inputs.home-manager-stable.nixosModules.home-manager ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        sharedModules = [
          gm.constants
          gm.system-constants
          inputs.self.modules.homeManager.catppuccin-stable
        ];
      };
    };
}
