{ inputs, ... }:
{
  flake.modules.nixos."development/vscode-server" =
    { ... }:
    {
      imports = [ inputs.vscode-server.nixosModules.default ];
      services.vscode-server.enable = true;
    };
}
