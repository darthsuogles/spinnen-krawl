#!/bin/bash

export TURBOVNC_VERSION=2.1.2
export VIRTUALGL_VERSION=2.5.2
export LIBJPEG_VERSION=1.5.2
export WEBSOCKIFY_VERSION=0.8.0
export NOVNC_VERSION=1.0.0-beta

function apt_install { sudo apt-get update && sudo apt-get install -y --no-install-recommends $@; }

apt_install \
    ca-certificates \
    curl \
    gcc \
    libc6-dev \
    libglu1 \
    libsm6 \
    libxv1 \
    make \
    python \
    python-numpy \
    x11-xkb-utils \
    xauth \
    xfonts-base \
    xkb-data


_URL_PREFIX=https://svwh.dl.sourceforge.net/project

pushd /tmp
curl -fsSL \
     -O ${_URL_PREFIX}/turbovnc/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
     -O ${_URL_PREFIX}/libjpeg-turbo/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb \
     -O ${_URL_PREFIX}/virtualgl/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb
sudo dpkg -i *.deb
rm -f *.deb
popd


curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz \
    | tar -xzf - -C ~/local
curl -fsSL https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz \
    | tar -xzf - -C ~/local
ln -s ~/local/noVNC-${NOVNC_VERSION} ~/local/noVNC
ln -s ~/local/websockify-${WEBSOCKIFY_VERSION} ~/local/websockify
ln -s ~/local/noVNC/vnc_lite.html ~/local/noVNC/index.html
(cd ~/local/websockify && make)
