set -e

pushd $HOME/nixos-config

echo "Reminder to input the password as nom noms the prompt"
sudo nixos-rebuild switch --flake $1 2>&1 | tee last-rebuild.log | nom

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    cat last-rebuild.log | grep --color error
    notify-send -e "NixOS rebuild failed." --icon=dialog-error
    exit 1
fi

current_gen=$(nixos-rebuild list-generations --json | jq '.[] | select(.current == true)')

gen_num=$(echo "$current_gen" | jq -r '.generation')
gen_date=$(echo "$current_gen" | jq -r '.date')
nixos_ver=$(echo "$current_gen" | jq -r '.nixosVersion')

current="NixOS generation $gen_num ($gen_date): nixos $nixos_ver"

git add .
git commit -m "$current"

popd

notify-send -e "NixOS rebuild complete" --icon=dialog-information