#! /bin/bash
upower -i $(upower -e |sed -n '2p') | awk  '/percentage/{print "BAT0:" $2}'
