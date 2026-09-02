{
  description = "Development shell for nixos-config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      repoRoot = ../.;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
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
          ];
          buildInputs = with pkgs; [ bashInteractive ];
          shellHook = ''
            source ${repoRoot}/apps/shell-hook/main.sh
          '';
        };
      }
    );
}
