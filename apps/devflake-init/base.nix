{
  description = "A flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    sandbox = {
      url = "github:mistercricro8/nixos-config?dir=extra";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      sandbox,
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
        ldPkgs = with pkgs; [
          stdenv.cc.cc
          zlib
          glib
          libxcb
          libglvnd
        ];
        sandboxEnv = sandbox.lib.mkSandbox {
          inherit pkgs;
          sandboxPkgs = shellPkgs;
          runtimeLibs = ldPkgs;
          hostAllowedBins = [ "agy" "docker" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath ldPkgs;
          packages = pkgs.lib.flatten [
            shellPkgs
            [ sandboxEnv.runner ]
          ];
          shellHook = "";
          buildInputs = [ pkgs.bashInteractive ];
        };
      }
    );
}
