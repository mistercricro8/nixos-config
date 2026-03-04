# Configuration for hosts that work as servers
{ inputs, ... }:
{
  flake.modules.nixos.system-server = {
    imports = with inputs.self.modules; [
      nixos.system-default
      nixos.builder
    ];
  };
}
