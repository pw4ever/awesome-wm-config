#!/bin/bash - 
#synclient TouchpadOff=$(synclient -l | grep -c 'TouchpadOff.*=.*0')

d='ETPS/2 Elantech Touchpad'
p='138'
a=$(xinput list-props  "$d"|awk "/$p/{print !\$4}")
echo Now: $a
xinput set-prop "$d" "$p"  $a
