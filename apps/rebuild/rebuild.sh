#!/usr/bin/env bash
set -eo pipefail

show_help() {
    cat << 'EOF'
Usage: rebuild [options] [target] [-- deploy-rs options...]

Options:
  -b, --build-host <host>   Sync repository to <host> via rsync and run deploy-rs on <host>
  -h, --help                Show this help message

Target:
  <node>                    Deploy specific node (e.g. cricro-pc or .#cricro-pc)
  <node>.<profile>          Deploy specific profile on node (e.g. cricro-pc.system)
  (none)                    Deploy all nodes defined in flake.deploy

Examples:
  rebuild cricro-pc
  rebuild cricro-pc --skip-checks
  rebuild -b cricro-l2 cricro-pc -- --skip-checks
  rebuild --remote-build
EOF
}

build_host=""
target=""
deploy_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--build-host)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "[ERROR] Missing value for --build-host" >&2
                exit 1
            fi
            build_host="$2"
            shift 2
            ;;
        --build-host=*)
            build_host="${1#*=}"
            shift
            ;;
        --)
            shift
            deploy_args+=("$@")
            break
            ;;
        -*)
            deploy_args+=("$1")
            shift
            ;;
        *)
            if [[ -z "$target" ]]; then
                target="$1"
            else
                deploy_args+=("$1")
            fi
            shift
            ;;
    esac
done

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Resolve target syntax for deploy-rs
if [[ -z "$target" ]]; then
    flake_target="."
elif [[ "$target" == .#* || "$target" == .* || "$target" == "#"* ]]; then
    flake_target="$target"
else
    flake_target=".#${target}"
fi

if [[ -n "$build_host" ]]; then
    echo "[INFO] Synchronizing repository to ${build_host}:~/.current-nixos-rebuild/ ..."
    rsync -av --delete --info=progress2 --filter=':- .gitignore' "${repo_dir}/" "${build_host}:~/.current-nixos-rebuild/"
    echo "[INFO] Synced to ${build_host}:~/.current-nixos-rebuild/"

    echo "[INFO] Deploying ${flake_target} via deploy-rs on ${build_host}..."
    ssh_cmd=("cd ~/.current-nixos-rebuild &&")
    ssh_cmd+=("if command -v deploy &>/dev/null; then deploy ${flake_target}")
    for arg in "${deploy_args[@]}"; do
        ssh_cmd+=("$(printf '%q' "$arg")")
    done
    ssh_cmd+=("; else nix run github:serokell/deploy-rs -- ${flake_target}")
    for arg in "${deploy_args[@]}"; do
        ssh_cmd+=("$(printf '%q' "$arg")")
    done
    ssh_cmd+=("; fi")

    # shellcheck disable=SC2029
    ssh "${build_host}" "${ssh_cmd[*]}"
else
    echo "[INFO] Deploying ${flake_target} via deploy-rs locally..."
    cd "${repo_dir}"
    if command -v deploy &>/dev/null; then
        deploy "${flake_target}" "${deploy_args[@]}"
    else
        nix run github:serokell/deploy-rs -- "${flake_target}" "${deploy_args[@]}"
    fi
fi