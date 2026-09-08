{
  description = "Reusable bubblewrap sandbox shell mixin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    let
      mkSandbox =
        { pkgs
        , sandboxPkgs ? with pkgs; [ bashInteractive coreutils git curl ]
        , hostAllowedBins ? [  ]
        , runtimeLibs ? with pkgs; [ stdenv.cc.cc.lib zlib glib libxcb libglvnd ]
        , extraBinds ? [ ]
        , extraBwrapArgs ? [ ]
        }:
        let
          HOST_BIN_DIR = "/run/host-bin";
          SANDBOX_USR_MOUNT = "/usr";
          SANDBOX_PATH = "/usr/bin:/run/host-bin";
          X86_64_LOADER_FILE = "ld-linux-x86-64.so.2";
          AARCH64_LOADER_FILE = "ld-linux-aarch64.so.1";

          ldLibraryPath = pkgs.lib.makeLibraryPath runtimeLibs;

          usrEnv = pkgs.buildEnv { name = "sandbox-usr"; paths = sandboxPkgs; };

          isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
          loaderFile = if isAarch64 then AARCH64_LOADER_FILE else X86_64_LOADER_FILE;
          loaderStorePath = "${pkgs.glibc}/lib/${loaderFile}";

          loaderArgs =
            if isAarch64
            then "--dir /lib --ro-bind ${loaderStorePath} /lib/${loaderFile}"
            else "--dir /lib64 --ro-bind ${loaderStorePath} /lib64/${loaderFile} --symlink /lib64 /lib";

          renderExtraBind = b:
            let dest = b.dest or b.src; in
            if b.mode == "--bind" || b.mode == "--ro-bind"
            then "add_bind ${pkgs.lib.escapeShellArg b.mode} ${pkgs.lib.escapeShellArg b.src} ${pkgs.lib.escapeShellArg dest}"
            else throw "mkSandbox.extraBinds: unsupported mode '${b.mode}' (expected --bind or --ro-bind)";
          renderedExtraBinds = pkgs.lib.concatStringsSep "\n" (map renderExtraBind extraBinds);
          renderedExtraBwrapArgs = pkgs.lib.concatStringsSep " " extraBwrapArgs;

          runner = pkgs.writeShellScriptBin "enter-sandbox" ''
            set -euo pipefail

            EXTRA_BINDS=()

            add_bind() {
              if [ -d "$2" ]; then
                EXTRA_BINDS+=(--dir "$3")
              fi
              EXTRA_BINDS+=("$1" "$2" "$3")
            }

            ${renderedExtraBinds}

            while [[ $# -gt 0 ]]; do
              case "''${1-}" in
                --bind|--ro-bind)
                  MODE="''${1-}"
                  if [[ $# -ge 3 && "''${3-}" != -* ]]; then
                    SRC="''${2-}"
                    DEST="''${3-}"
                    shift 3
                  elif [[ $# -ge 2 ]]; then
                    SRC="''${2-}"
                    DEST="''${2-}"
                    shift 2
                  else
                    echo "enter-sandbox: $MODE requires a source path" >&2
                    exit 2
                  fi
                  add_bind "$MODE" "$SRC" "$DEST"
                  ;;
                --)
                  shift
                  break
                  ;;
                *)
                  break
                  ;;
              esac
            done

            CMD=("''${@:-bash}")

            HOST_BIN_MOUNTS=(--dir ${HOST_BIN_DIR})
            ALLOWED_BINS=(${pkgs.lib.concatMapStringsSep " " pkgs.lib.escapeShellArg hostAllowedBins})

            for bin in "''${ALLOWED_BINS[@]}"; do
              BIN_PATH=""
              if [ -x "/run/current-system/sw/bin/$bin" ]; then
                BIN_PATH="/run/current-system/sw/bin/$bin"
              elif command -v "$bin" >/dev/null 2>&1; then
                BIN_PATH="$(command -v "$bin")"
              fi

              if [ -n "$BIN_PATH" ]; then
                HOST_BIN_MOUNTS+=(--ro-bind "$BIN_PATH" "${HOST_BIN_DIR}/$bin")
              else
                echo "Warning: Host binary '$bin' not found on host system." >&2
              fi
            done

            exec ${pkgs.bubblewrap}/bin/bwrap \
              --unshare-all \
              --share-net \
              --die-with-parent \
              \
              --ro-bind /nix/store /nix/store \
              --ro-bind ${usrEnv} ${SANDBOX_USR_MOUNT} \
              \
              ${loaderArgs} \
              \
              "''${HOST_BIN_MOUNTS[@]}" \
              \
              --proc /proc \
              --dev /dev \
              --tmpfs /tmp \
              \
              --dir "$HOME" \
              --dir "$(pwd)" \
              --bind "$(pwd)" "$(pwd)" \
              --ro-bind /etc/resolv.conf /etc/resolv.conf \
              --ro-bind-try /etc/ssl /etc/ssl \
              --ro-bind-try /etc/static/ssl /etc/static/ssl \
              \
              ${renderedExtraBwrapArgs} \
              "''${EXTRA_BINDS[@]}" \
              \
              --chdir "$(pwd)" \
              --setenv PATH "${SANDBOX_PATH}" \
              --setenv LD_LIBRARY_PATH "${ldLibraryPath}" \
              --setenv HOME "$HOME" \
              --setenv TERM "$TERM" \
              -- "''${CMD[@]}"
          '';
        in
        { inherit runner ldLibraryPath; };
    in
    {
      lib = { inherit mkSandbox; };
    } // flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        demo = mkSandbox { inherit pkgs; };
      in
      {
        packages.enter-sandbox-demo = demo.runner;
        devShells.default = pkgs.mkShell {
          packages = [ demo.runner ];
          shellHook = demo.shellHook;
        };
      });
}
