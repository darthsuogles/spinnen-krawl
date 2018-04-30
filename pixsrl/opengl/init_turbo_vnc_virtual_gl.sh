#!/bin/bash

docker run \
       --init \
       --runtime=nvidia \
       --name=vnc-virtual-gl \
       --rm -i \
       -v "/usr/lib/x86_64-linux-gnu/xorg/extra-modules":"/usr/lib/x86_64-linux-gnu/xorg/extra-modules":ro \
       --privileged \
       -p 5901:5901 \
       vnc-virtual-gl
