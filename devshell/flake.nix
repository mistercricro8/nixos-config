{
  description = "Development shell for nixos-config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    sandbox.url = "path:../extra";
    sandbox.inputs.nixpkgs.follows = "nixpkgs";
    sandbox.inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      sandbox,
      ...
    }:
    let
      repoRoot = ../.;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        sandboxEnv = sandbox.lib.mkSandbox { inherit pkgs; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            opentofu
            oci-cli
            jq
            ssh-to-age
            age
            sops
            nix-output-monitor
            nixd
            nixfmt
            sandboxEnv.runner
          ];
          buildInputs = with pkgs; [ bashInteractive ];
          shellHook = ''
            source ${repoRoot}/apps/shell-hook/main.sh
          '';
        };
      }
    );
}
