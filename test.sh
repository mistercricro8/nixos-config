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