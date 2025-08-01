set -e

pushd $HOME/nixos-config &>/dev/null

args=("$@")

flags=()
for arg in "${args[@]}"; do
    if [[ $arg == --* ]]; then
        case "$arg" in
            --help)
                echo "Usage: nix-rebuild [--options] .#derivation"
                echo "Options:"
                echo "  --help        Show this help message"
                echo "  --no-commit   Skip committing changes to git"
                exit 0
                ;;
            --no-commit)
                flags+=("$arg")
                ;;
        esac
    else
        derivation="$arg"
    fi
done

if [[ -z "${derivation}" || ! "${derivation}" =~ ^\.\#.+$ ]]; then
    echo "Error: No valid derivation specified."
    echo "Usage: nix-rebuild [--options] .#derivation"
    exit 1
fi

available_derivations=($(nix flake show --json . | jq -r '.nixosConfigurations | keys[]' | sed 's/^/.#/'))

if [[ ! " ${available_derivations[@]} " =~ " ${derivation} " ]]; then
    echo "Error: Derivation '${derivation}' not found in the system flake."
    echo -e "Available derivations:\n${available_derivations[@]}"
    exit 1
fi

echo "Reminder to input the password as nom noms the prompt"
sudo nixos-rebuild switch --flake "${derivation}" 2>&1 | tee last-rebuild.log | nom

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    cat last-rebuild.log | grep --color error
    notify-send -e "NixOS rebuild failed." --icon=dialog-error
    exit 1
fi

if [[ ! " ${flags[@]} " =~ " --no-commit " ]]; then
    current_gen=$(nixos-rebuild list-generations --json | jq '.[] | select(.current == true)')

    gen_num=$(echo "$current_gen" | jq -r '.generation')
    gen_date=$(echo "$current_gen" | jq -r '.date')
    nixos_ver=$(echo "$current_gen" | jq -r '.nixosVersion')

    current="NixOS generation $gen_num ($gen_date): nixos $nixos_ver"
    git add .
    git commit -m "$current"
fi

popd &>/dev/null

notify-send -e "NixOS rebuild complete" --icon=dialog-information