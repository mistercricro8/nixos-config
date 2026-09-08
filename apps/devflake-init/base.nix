{
  description = "A flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    sandbox.url = "github:mistercricro8/nixos-config?dir=extra";
    sandbox.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sandbox.inputs.flake-utils.follows = "flake-utils";
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
        sandboxEnv = sandbox.lib.mkSandbox { inherit pkgs; };
      in
      {
        devShells.default = pkgs.mkShell {
          LD_LIBRARY_PATH =
            with pkgs;
            lib.makeLibraryPath [
              stdenv.cc.cc
              zlib
              glib
              libxcb
              libglvnd
            ];

          packages = pkgs.lib.flatten [
            (with pkgs; [
            ])
            (with unstable; [
            ])
            [
              sandboxEnv.runner
            ]
          ];
          shellHook = "";
          buildInputs = [ pkgs.bashInteractive ];
        };
      }
    );
}
