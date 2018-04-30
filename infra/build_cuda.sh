#!/bin/bash

# http://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#ubuntu-installation
# The public key
cuda_repo_public_key=https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub

function apt_install_cuda {
    # Install this so that we can fetch https resources
    sudo apt-get install gnupg-curl
    sudo apt-key adv --fetch-keys "${cuda_repo_public_key}"

    sudo apt-get install -y \
        curl \
        git \
        libcudnn7=7.0.5.15-1+cuda9.0 \
        libcudnn7-dev=7.0.5.15-1+cuda9.0
}

function apt_install_deps {
    apt-get update && apt-get install -y --no-install-recommends \
			      build-essential \
			      curl \
			      git \
			      golang \
			      libcurl3-dev \
			      libfreetype6-dev \
			      libpng12-dev \
			      libzmq3-dev \
			      pkg-config \
			      python-dev \
			      python-pip \
			      rsync \
			      software-properties-common \
			      unzip \
			      zip \
			      zlib1g-dev \
			      openjdk-8-jdk \
			      openjdk-8-jre-headless \
			      wget
}

# apt_install_deps
apt_install_cuda
