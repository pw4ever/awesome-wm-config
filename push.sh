#!/bin/bash - 

# http://stackoverflow.com/a/246128/1527494
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SRC=${DIR}/autostart
DST=~/.config/autostart
mkdir -p ${DST}
cp -rv ${SRC} ${DST}
