{
  description = "A flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        shellPkgs = pkgs.lib.flatten [
          (with pkgs; [
          ])
          (with unstable; [
          ])
        ];
        ldLibraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          zstd
          openssl
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = shellPkgs;
          shellHook = "";
          env = {
            NIX_LD = "${pkgs.stdenv.cc.bintools.dynamicLinker}";
            NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath ldLibraries;
          };
          buildInputs = [ pkgs.bashInteractive ];
        };
      }
    );
}
