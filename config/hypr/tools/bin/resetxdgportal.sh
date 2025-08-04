#!/usr/bin/env bash

echo "$PATH" > "/home/lhussonn/test.log"
sleep 1
killall xdg-desktop-portal-hyprland
killall xdg-desktop-portal-gnome
killall xdg-desktop-portal-kde
killall xdg-desktop-portal-lxqt
killall xdg-desktop-portal-wlr
killall xdg-desktop-portal
sleep 1

# Resolve libexec directory for portals
if [ -d /run/current-system/sw/libexec ]; then
    libDir=/run/current-system/sw/libexec
elif [ -d /usr/libexec ]; then
    libDir=/usr/libexec
else
    libDir=/usr/lib
fi

$libDir/xdg-desktop-portal-hyprland &
sleep 2
$libDir/xdg-desktop-portal &
