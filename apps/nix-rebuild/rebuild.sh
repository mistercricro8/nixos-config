#!/run/current-system/sw/bin/bash
set -e

pushd "$HOME"/nixos-config &>/dev/null

RED='\033[0;31m'
RESET='\033[0m'

AUTOROLLBACK_WAIT_TIME=60

args=("$@")

no_commit=false
push=false
update_flake=false
no_exec_mode=false
test_mode=false
autorollback=false
local_only=false
keepalive_pid=""

ensure_sudo_timestamp() {
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    if ! sudo -v; then
        echo "Failed to authenticate with sudo."
        exit 1
    fi
}

start_sudo_keepalive() {
    sudo -n -v || return 1
    while true; do
        sleep 60
        sudo -n -v || return 0
    done
}

cleanup_keepalive() {
    if [[ -n "${keepalive_pid}" ]]; then
        if kill -0 "${keepalive_pid}" 2>/dev/null; then
            kill "${keepalive_pid}" 2>/dev/null || true
        fi
        wait "${keepalive_pid}" 2>/dev/null || true
        keepalive_pid=""
    fi
}

trap cleanup_keepalive EXIT

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

maybe_notify() {
    local title="$1"
    local body="$2"
    local icon="$3"

    if ! command_exists notify-send; then
        return 0
    fi

    local args=(-e)
    [[ -n "$icon" ]] && args+=(--icon="$icon")

    if [[ -n "$body" ]]; then
        notify-send "${args[@]}" "$title" "$body"
    else
        notify-send "${args[@]}" "$title"
    fi
}

maybe_wall() {
    if command_exists wall; then
        wall "$@"
    else
        echo "$@"
    fi
}

# ---------------- Parsing ----------------

for arg in "${args[@]}"; do
    if [[ $arg == --* ]]; then
        case "$arg" in
        --help)
            echo "Usage: nix-rebuild [--options] .#derivation"
            echo ".#derivation          Specify the derivation to rebuild"
            echo
            echo "Options:"
            echo "  --help              Show this help message"
            echo "  --no-commit         Skip committing changes to git"
            echo "  --push              Push changes to the remote repository"
            echo "  --update-flake      Update the flake before rebuilding"
            echo "  --no-exec           Only executes until the summary step"
            echo "  --autorollback      Automatically rollback on failure to remove /tmp/nixos-rebuild-rollback"
            echo "  --local-only        Don't use remote builders"
            echo "  --test              Calls test to nixos-rebuild instead of switch"
            exit 0
            ;;
        --no-commit)
            no_commit=true
            ;;
        --push)
            push=true
            ;;
        --update-flake)
            update_flake=true
            ;;
        --no-exec)
            no_exec_mode=true
            ;;
        --test)
            test_mode=true
            ;;
        --autorollback)
            autorollback=true
            ;;
        --local-only)
            local_only=true
            ;;
        *)
            echo "Unknown option: $arg"
            ;;
        esac
    else
        derivation="$arg"
    fi
done

# ---------------- Checks ----------------

if [[ "$push" == true && "$no_commit" == true ]]; then
    echo "Error: --push cannot be used with --no-commit."
    exit 1
fi

if [[ -z "${derivation}" || ! "${derivation}" =~ ^\.\#.+$ ]]; then
    echo "Error: No valid derivation specified."
    echo "Usage: nix-rebuild [--options] .#derivation"
    exit 1
fi

mapfile -t available_derivations < <(nix flake show --json . | jq -r '.nixosConfigurations | keys[]' | sed 's/^/.#/')

if [[ ! " ${available_derivations[*]} " =~ ${derivation} ]]; then
    echo "Error: Derivation '${derivation}' not found in the system flake."
    echo -e "Available derivations:\n${available_derivations[*]}"
    exit 1
fi

# ---------------- Summary ----------------

echo "Summary:"
echo "  Derivation ${derivation} will be rebuilt and used."
if [[ "$no_commit" == true ]]; then
    echo "  Changes will NOT be committed."
elif [[ "$push" == true ]]; then
    echo "  Changes will be committed and pushed."
else
    echo "  Changes will be committed."
fi
if [[ "$update_flake" == true ]]; then
    echo "  Flake will be updated before rebuilding."
fi
if [[ "$test_mode" == true ]]; then
    echo "  NixOS rebuild will be run in test mode."
fi
if [[ "$local_only" == true ]]; then
    echo "  Remote builders will NOT be used."
fi
if [[ "$autorollback" == true ]]; then
    echo "  After the rebuild, manually remove /tmp/nixos-rebuild-rollback to ensure connectivity."
fi

echo

if [[ "$no_exec_mode" == true ]]; then
    exit 0
fi

# ---------------- Execution ----------------

git add .

if [[ "$update_flake" == true ]]; then
    echo "Updating flake..."
    nix flake update
    git add .
fi

if [[ "$test_mode" == true ]]; then
    rebuild_command="test"
else
    rebuild_command="switch"
fi

builders_args=()
if [[ "$local_only" == true ]]; then
    builders_args=(--builders "")
fi

echo "Will execute: nixos-rebuild ${rebuild_command} ${builders_args[*]} --show-trace --flake ${derivation} --sudo"
echo
echo -e "Enter to ${RED}proceed${RESET}."
read -r

ensure_sudo_timestamp
start_sudo_keepalive &
keepalive_pid=$!

output_consumer=(cat)
if command_exists nom; then
    output_consumer=(nom)
fi

nixos-rebuild "${rebuild_command}" "${builders_args[@]}" --show-trace --flake "${derivation}" --sudo 2>&1 |
    tee last-rebuild.log |
    "${output_consumer[@]}"

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    grep --color error last-rebuild.log
    maybe_notify "NixOS rebuild failed." "Check last-rebuild.log for details." "dialog-error"
    exit 1
fi

if [[ "$autorollback" == true ]]; then
    touch /tmp/nixos-rebuild-rollback
    echo "==============================="
    echo "Autorollback is enabled."
    echo "Manually remove the file /tmp/nixos-rebuild-rollback"
    echo "==============================="

    remaining_time=$AUTOROLLBACK_WAIT_TIME
    will_rollback=true
    while [[ $remaining_time -gt 0 ]]; do
        if [[ ! -f /tmp/nixos-rebuild-rollback ]]; then
            echo "Autorollback cancelled."
            break
        fi
        maybe_wall "Rollback in $remaining_time seconds. Remove /tmp/nixos-rebuild-rollback to prevent it."
        sleep 10
        ((remaining_time -= 10))
    done

    if [[ -f /tmp/nixos-rebuild-rollback ]]; then
        sudo nixos-rebuild switch --rollback --flake "${derivation}"
    fi
fi

if [[ "$no_commit" == false ]]; then
    current_gen=$(nixos-rebuild list-generations --json | jq '.[] | select(.current == true)')

    gen_num=$(echo "$current_gen" | jq -r '.generation')
    gen_date=$(echo "$current_gen" | jq -r '.date')

    current="NixOS generation $gen_num ($gen_date): derivation $derivation"

    echo
    echo "Enter commit message (description):"
    maybe_notify "Awaiting commit message..."
    read -r commit_message

    if [[ -n "$commit_message" ]]; then
        git commit -m "$current" -m "$commit_message"
    else
        git commit -m "$current"
    fi

    if [[ "$push" == true ]]; then
        git push
    fi
fi

popd &>/dev/null

maybe_notify "NixOS rebuild complete" "Rebuild succeeded." "dialog-information"
