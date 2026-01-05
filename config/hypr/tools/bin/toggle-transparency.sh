#!/bin/bash

current_value=$(hyprctl getprop activewindow opaque)
if [ "$current_value" = "true" ]; then
  hyprctl dispatch setprop activewindow opaque off
else
  hyprctl dispatch setprop activewindow opaque on
fi
