#!/bin/bash - 

set -o nounset                              # Treat unset variables as an error

change=${1:-0}
shift

target=${1:-nv_backlight}
shift

path=/sys/class/backlight/${target}
path_max=${path}/max_brightness
path_cur=${path}/brightness

max=$(cat ${path_max})
min=10
cur=$(cat ${path_cur})

new=$((cur + change))

if (( new > max )); then
    new=$max;
fi

if (( new < min )); then
    new=$min
fi


echo $new | sudo tee ${path_cur}
