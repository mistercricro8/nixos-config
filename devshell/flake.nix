{
  description = "Development shell for nixos-config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      sops-nix,
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
          nativeBuildInputs = [
            sops-nix.packages.${system}.sops-import-keys-hook
          ];
          sopsPGPKeyDirs = [
            (repoRoot + "/keys")
          ];
          packages = with pkgs; [
            opentofu
            oci-cli
            jq
            ssh-to-pgp
            sops
            nix-output-monitor
          ];
          buildInputs = with pkgs; [ bashInteractive ];
          shellHook = ''
            source ${repoRoot}/apps/shell-hook/main.sh
          '';
        };
      }
    );
}
