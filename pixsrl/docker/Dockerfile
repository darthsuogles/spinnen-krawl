FROM ubuntu:xenial

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        scons \
        mercurial \

        libpng12-dev \
        libjpeg-dev \
        libilmbase-dev \
        libxerces-c-dev \
        libboost-all-dev \
        libopenexr-dev \
        libglewmx-dev \
        libxxf86vm-dev \
        libpcrecpp0v5 \
        libeigen3-dev \
        libfftw3-dev \
        libcurl3-dev \
        libfreetype6-dev \
        libzmq3-dev \
        pkg-config \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        wget \
        && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fSsL -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py
