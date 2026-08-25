{ lib, ... }:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
    description = "Shared helper functions exposed on inputs.self.lib.";
  };

  options.flake.factories = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
    description = "Parametric feature factories. Exposed on inputs.self.factories.";
  };
}
