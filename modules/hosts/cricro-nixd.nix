# Dummy host for nixd LSP type-checking.
{ inputs, ... }:
{
  flake.modules.nixos."cricro-nixd" =
    { ... }:
    let
      m = inputs.self.modules;
    in
    {
      imports = with m; [
        nixos.system-default
        nixos.catppuccin
        nixos.sBoot
        nixos.sSamba
        nixos.sTailscale
      ];

      networking.hostName = "nixd";

      sBoot.enable = false;
      sSamba.enable = false;
      sTailscale.enable = false;

      system.stateVersion = "24.05";
    };
}
