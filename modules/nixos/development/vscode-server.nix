{ inputs, ... }:
{
  flake.modules.nixos."development/vscode-server" =
    { ... }:
    {
      imports = [ inputs.vscode-server.nixosModules.default ];
      services.vscode-server.enable = true;

      systemd.user.services.auto-fix-vscode-server = {
        unitConfig.ConditionPathIsReadWrite = "%h";
      };
    };
}

