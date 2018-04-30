#!/bin/bash

~/local/websockify/run 5901 \
                       --web=$HOME/local/noVNC \
                       --wrap-mode=ignore \
                       -- \
                       /opt/TurboVNC/bin/vncserver \
                       :1 \
                       -securitytypes otp -otp \
                       -autokill
