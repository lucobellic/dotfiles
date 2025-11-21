#!/bin/bash

for prop in alpha alphafullscreen; do
	current_value=$(hyprctl getprop activewindow "$prop")
	if [ "$current_value" = "1" ]; then
		hyprctl dispatch setprop activewindow "$prop" 0.8
	else
		hyprctl dispatch setprop activewindow "$prop" 1.0
	fi
done
