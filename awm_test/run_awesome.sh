#!/bin/bash
# start 800x600 nested x server

aconf=$1
display=$2
test -n $display || display=":1.0"

Xephyr -ac -nolisten tcp -br -noreset -screen 1024x768 ${display}


if [ -f "${aconf}"  ]; then
    DISPLAY="${display}"
    awesome -c ${aconf};
else
   exit 1
fi
