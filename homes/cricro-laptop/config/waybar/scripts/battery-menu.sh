#!/usr/bin/env bash

config="$HOME/.config/rofi/power-menu.rasi"

actions=$(echo -e " Performance\n󰂂 Balanced\n Power-Saver")

# Display logout menu
selected_option=$(echo -e "$actions" | rofi -dmenu -i -config "${config}" || pkill -x rofi)

# Perform actions based on the selected option
case "$selected_option" in
*Performance)
  powerprofilesctl set performance
  ;;
*Balanced)
  powerprofilesctl set balanced
  ;;
*Power-Saver)
  powerprofilesctl set power-saver
  ;;
esac
