# Global helper functions.
{ inputs, lib, ... }:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
    description = "Shared helper functions exposed on inputs.self.lib.";
  };

  # Filter a list of packages by whether they are supported on the current host platform.
  # pkgs       - the nixpkgs instance
  # packages   - the list of packages to filter
  config.flake.lib.filterPlatformPackages =
    pkgs: packages:
    lib.filter (
      p:
      let
        platforms = p.meta.platforms or null;
      in
      platforms == null || builtins.elem pkgs.stdenv.hostPlatform.system platforms
    ) packages;

  # Create a NixOS system configuration based on the provided inputs.
  # system     - system architecture (e.g. "x86_64-linux")
  # name       - host name of the system
  # branch     - specific nixpkgs branch to use ("stable" or "unstable" default: "unstable")
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
