#!/bin/bash

aconf=$1
display=$2
test -n $display || display=":1.0"

if [ -f "${aconf}"  ]; then
    DISPLAY="${display}"
    awesome -c ${aconf};
else
   exit 1
fi
