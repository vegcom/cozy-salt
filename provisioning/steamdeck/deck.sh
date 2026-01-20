#!/bin/sh
case $1/$2 in
  pre/*)
    echo "Going to $2..."
    ;;
  post/*)
    echo "Waking up from $2..."
    xrandr --output eDP  --mode 800x1280 --pos 0x280 --rotate right
    xinput --map-to-output 'pointer:FTS3528:00 2808:1015' eDP
    ;;
esac
