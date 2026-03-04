# Main flake that registers all hosts
{ inputs, lib, ... }:
let
  mkNixos = inputs.self.lib.mkNixos;
  mkBootstrap =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        inputs.self.modules.nixos."cricro-bootstrap"
        { nixpkgs.hostPlatform = system; }
      ];
    };
in
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  debug = true;

  flake.nixosConfigurations = lib.mergeAttrsList [
    (mkNixos {
      system = "x86_64-linux";
      name = "cricro-pc";
    })
    (mkNixos {
      system = "x86_64-linux";
      name = "cricro-laptop";
    })
    (mkNixos {
      system = "x86_64-linux";
      name = "cricro-l2";
    })
    (mkNixos {
      system = "aarch64-linux";
      name = "cricro-vm";
      branch = "stable";
    })
    {
      bootstrap-x86 = mkBootstrap "x86_64-linux";
      bootstrap-aarch64 = mkBootstrap "aarch64-linux";
    }
  ];
}
