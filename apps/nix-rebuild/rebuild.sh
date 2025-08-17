#!/run/current-system/sw/bin/bash
set -e

pushd "$HOME"/nixos-config &>/dev/null

RED='\033[0;31m'
RESET='\033[0m'

args=("$@")

no_commit=false
push=false
update_flake=false
test_mode=false

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
            echo "  --test              Only executes until the summary step"
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
        --test)
            test_mode=true
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

echo

echo -e "Enter to ${RED}proceed${RESET}."
read -r

if [[ "$test_mode" == true ]]; then
    exit 0
fi

# ---------------- Execution ----------------

git add .

if [[ "$update_flake" == true ]]; then
    echo "Updating flake..."
    nix flake update
    git add .
fi

echo "Reminder to input the password as nom noms the prompt"
sudo nixos-rebuild switch --flake "${derivation}" 2>&1 | tee last-rebuild.log | nom

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    grep --color error last-rebuild.log
    notify-send -e "NixOS rebuild failed." --icon=dialog-error
    exit 1
fi

if [[ "$no_commit" == false ]]; then
    current_gen=$(nixos-rebuild list-generations --json | jq '.[] | select(.current == true)')

    gen_num=$(echo "$current_gen" | jq -r '.generation')
    gen_date=$(echo "$current_gen" | jq -r '.date')
    nixos_ver=$(echo "$current_gen" | jq -r '.nixosVersion')

    current="NixOS generation $gen_num ($gen_date): nixos $nixos_ver"
    git commit -m "$current"

    if [[ "$push" == true ]]; then
        git push
    fi
fi

popd &>/dev/null

notify-send -e "NixOS rebuild complete" --icon=dialog-information
