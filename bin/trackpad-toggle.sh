#!/bin/bash - 
synclient TouchpadOff=$(synclient -l | grep -c 'TouchpadOff.*=.*0')
