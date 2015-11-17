#!/bin/bash - 
#synclient TouchpadOff=$(synclient -l | grep -c 'TouchpadOff.*=.*0')
xinput set-prop 14 138 $(xinput list-props  14|awk '/138/{print !$4} ')
