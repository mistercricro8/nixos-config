{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.disko.flakeModules.default
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
}
