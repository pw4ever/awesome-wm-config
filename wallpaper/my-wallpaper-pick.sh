#!/bin/sh

if [[ -n $1 ]]; then
    sleep=$1
else
    sleep=1m
fi

while true; do
    find . -type f \( -name '*.jpg' -o -name '*.png' \) -print0 | shuf -n1 -z | xargs -0 feh --bg-scale
    sleep ${sleep}
done
