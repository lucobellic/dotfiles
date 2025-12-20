#!/usr/bin/env bash

scrDir=`dirname "$(realpath "$0")"`
source $scrDir/globalcontrol.sh

hyprctl switchxkblayout at-translated-set-2-keyboard next
hyprctl switchxkblayout splitkb.com-kyria-rev4 next

layMain=$(hyprctl -j devices | jq '.keyboards' | jq '.[] | select (.main == true)' | awk -F '"' '{if ($2=="active_keymap") print $4}')
notify-send -a "t1" -r 91190 -t 800 -i "~/.config/dunst/icons/keyboard.svg" "${layMain}"

