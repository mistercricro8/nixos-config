#!/usr/bin/env bash

config="$HOME/.config/rofi/power-menu.rasi"

current=$(powerprofilesctl get)

# Add a checkmark to the current profile using case
case "$current" in
  performance)
    actions=" Performance ✓\n󰂂 Balanced\n Power-Saver"
    ;;
  balanced)
    actions=" Performance\n󰂂 Balanced ✓\n Power-Saver"
    ;;
  *)
    actions=" Performance\n󰂂 Balanced\n Power-Saver ✓"
    ;;
esac

# Display logout menu
selected_option=$(echo -e "$actions" | rofi -dmenu -i -config "${config}" || pkill -x rofi)

# Perform actions based on the selected option
case "$selected_option" in
*Performance*)
  powerprofilesctl set performance
  ;;
*Balanced*)
  powerprofilesctl set balanced
  ;;
*Power-Saver*)
  powerprofilesctl set power-saver
  ;;
esac
