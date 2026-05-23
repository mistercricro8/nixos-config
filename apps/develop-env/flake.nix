{
  description = "A flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
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
        ldPath =
          with pkgs;
          lib.makeLibraryPath [
            stdenv.cc.cc
            zlib
            glib
            libxcb
            openssl
            libglvnd
          ];
      in
      {
        devShells.default = pkgs.mkShell {
          LD_LIBRARY_PATH = ldPath;

          packages = with pkgs; [
            uv

            nodejs
            pnpm

            go

            jdk21

            cargo
            rustc
            rustup
            openssl
          ];

          nativeBuildInputs = [ pkgs.pkg-config ];

          buildInputs = [ pkgs.bashInteractive ];

          env = {
            GOPROXY = "https://proxy.golang.org,direct";
            GOSUMDB = "sum.golang.org";
            JAVA_HOME = "${pkgs.jdk21}";
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          };

          shellHook = ''
            export GOPATH="$PWD/.go"
            export GOBIN="$GOPATH/bin"

            mkdir -p "$GOBIN"
            export PATH="$GOBIN:$PATH:$HOME/.cargo/bin:$HOME/.rustup/toolchains"
          '';
        };
      }
    );
}
