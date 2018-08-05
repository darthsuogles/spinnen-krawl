#!/bin/bash

set -euo pipefail

function install_docker {
    # https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#uninstall-old-versions
    # Remove exising docker versions
    sudo apt-get remove -y docker docker-engine docker.io

    sudo apt-get install -y \
	     apt-transport-https \
	     ca-certificates \
	     curl \
	     software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
	    sudo apt-key add -

    sudo apt-key fingerprint 0EBFCD88

    sudo add-apt-repository \
	     "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt-get update
    sudo apt-get install -y docker-ce

}

function install_nvidia_docker {
    # If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
    docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
    sudo apt-get purge -y nvidia-docker

    # Add the package repositories
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
	    sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu16.04/amd64/nvidia-docker.list | \
	    sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt-get update

    # Install nvidia-docker2 and reload the Docker daemon configuration
    sudo apt-get install -y nvidia-docker2
    sudo pkill -SIGHUP dockerd
}

install_docker
install_nvidia_docker
# Test nvidia-smi with the latest official CUDA image
docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi
