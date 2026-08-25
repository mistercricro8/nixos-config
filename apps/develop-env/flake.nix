{
  description = "Modular ad-hoc development environment";

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

        components = {
          python = {
            packages = with pkgs; [ uv python312 ];
          };

          node = {
            packages = with pkgs; [
              nodejs
              pnpm
            ];
          };

          go = {
            packages = with pkgs; [ go ];
            env = {
              GOPROXY = "https://proxy.golang.org,direct";
              GOSUMDB = "sum.golang.org";
            };
            shellHook = ''
              export GOPATH="$PWD/.go"
              export GOBIN="$GOPATH/bin"
              mkdir -p "$GOBIN"
              export PATH="$GOBIN:$PATH"
            '';
          };

          java = {
            packages = [ pkgs.jdk21 ];
            env = {
              JAVA_HOME = "${pkgs.jdk21}";
            };
          };

          rust = {
            packages = with pkgs; [
              cargo
              rustc
              rustup
              openssl
            ];
            env = {
              RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
            };
            shellHook = ''
              export PATH="$PATH:$HOME/.cargo/bin:$HOME/.rustup/toolchains"
            '';
          };
        };

        makeShell = names:
          let
            validNames = builtins.filter (name: builtins.hasAttr name components) names;
            selected = map (name: components.${name}) validNames;

            packages = pkgs.lib.concatLists (map (c: c.packages or []) selected);
            nativeBuildInputs = [ pkgs.pkg-config ] ++ pkgs.lib.concatLists (map (c: c.nativeBuildInputs or []) selected);
            buildInputs = [ pkgs.bashInteractive ] ++ pkgs.lib.concatLists (map (c: c.buildInputs or []) selected);

            mergedEnv = pkgs.lib.foldl' (acc: c: acc // (c.env or {})) {
              LD_LIBRARY_PATH = ldPath;
            } selected;

            shellHook = pkgs.lib.concatStringsSep "\n" (map (c: c.shellHook or "") selected);
          in
          pkgs.mkShell (mergedEnv // {
            inherit packages nativeBuildInputs buildInputs shellHook;
          });
      in
      {
        devShells = {
          python = makeShell [ "python" ];
          node = makeShell [ "node" ];
          go = makeShell [ "go" ];
          java = makeShell [ "java" ];
          rust = makeShell [ "rust" ];
          default = makeShell [ "python" "node" "go" "java" "rust" ];
        };
        lib = {
          inherit makeShell;
        };
      }
    );
}
