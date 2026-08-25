{ inputs, ... }:
{
  flake.modules.nixos."system/nur" =
    { ... }:
    {
      imports = [ inputs.nur.modules.nixos.default ];
    };
}
