# Enables the vscode server module
{ inputs, ... }:
{
  flake.modules.nixos.vscode-server = {
    imports = [ inputs.vscode-server.nixosModules.default ];
    services.vscode-server.enable = true;
  };
}
