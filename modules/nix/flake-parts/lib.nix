# Global helper functions.
{ inputs, lib, ... }:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
    description = "Shared helper functions exposed on inputs.self.lib.";
  };

  config.flake.lib.filterPlatformPackages =
    pkgs: packages:
    lib.filter (
      p:
      let
        platforms = p.meta.platforms or null;
      in
      platforms == null || builtins.elem pkgs.stdenv.hostPlatform.system platforms
    ) packages;

  config.flake.lib.mkNixos =
    {
      system,
      name,
      branch ? "unstable",
    }:
    let
      nixpkgs = if branch == "stable" then inputs.nixpkgs-stable else inputs.nixpkgs;
    in
    {
      ${name} = nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };
}
