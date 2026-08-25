{ inputs, ... }:
{
  flake.modules.nixos."system/server" =
    { ... }:
    {
      imports = (
        with inputs.self.modules;
        [
          nixos."system/default"
          nixos."system/settings/builder"
        ]
      );
    };
}
