#!/bin/bash

set -eu -o pipefail

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat <<_SCRIPT_LOCATION_WARNING_EOF_
==========================================
Please make sure this script is located
under the root directory of tensorflow.
==========================================
_SCRIPT_LOCATION_WARNING_EOF_

function quit_with { >& printf "ERROR: $@, exit"; exit 1; }

BASE_CONTAINER_IMAGE=nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04
#BASE_CONTAINER_IMAGE=tensorflow/tensorflow:latest-devel-gpu-py3

docker pull "${BASE_CONTAINER_IMAGE}"

pip_pkgs_file="${_bsd_}/tensorflow/tools/ci_build/install/install_python3.6_pip_packages.sh"
[[ -f "${pip_pkgs_file}" ]] || \
    quit_with "cannot find python package files, please make sure you are running in tensorflow git root"

docker_context_tmpdir="$(mktemp -d)"
grep -Ei '^pip' "${pip_pkgs_file}" | tee "${docker_context_tmpdir}/pip_install_commands"

nvidia-docker build "${docker_context_tmpdir}" \
	      --build-arg BASE_CONTAINER_IMAGE="${BASE_CONTAINER_IMAGE}" \
	      -t tensorflow-builder:base \
	      -f -<<'_DOCKERFILE_EOF_'
ARG BASE_CONTAINER_IMAGE
FROM ${BASE_CONTAINER_IMAGE}

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-10-0 \
        cuda-cublas-dev-10-0 \
        cuda-cudart-dev-10-0 \
        cuda-cufft-dev-10-0 \
        cuda-curand-dev-10-0 \
        cuda-cusolver-dev-10-0 \
        cuda-cusparse-dev-10-0 \
        curl \
        git \
        libnccl2 \
        libnccl-dev \
        libcurl3-dev \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libpng-dev \
        libzmq3-dev \
	openjdk-8-jdk \
	python3-dev \
        pkg-config \
        rsync \
        software-properties-common \
	swig \
        unzip \
        zip \
        zlib1g-dev \
        wget \
        && \
    find /usr/local/cuda-10.0/lib64/ -type f -name 'lib*_static.a' -not -name 'libcudart_static.a' -delete && \
    rm /usr/lib/x86_64-linux-gnu/libcudnn_static_v7.a

RUN curl -fSsL -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

RUN apt-get update && \
        apt-get install nvinfer-runtime-trt-repo-ubuntu1804-5.0.2-ga-cuda10.0 \
        && apt-get update \
        && apt-get install -y --no-install-recommends libnvinfer5=5.0.2-1+cuda10.0 \
        && apt-get install libnvinfer-dev=5.0.2-1+cuda10.0 \
        && rm -rf /var/lib/apt/lists/*

# Link NCCL libray and header where the build script expects them.
RUN mkdir /usr/local/cuda-10.0/lib &&  \
    ln -s /usr/lib/x86_64-linux-gnu/libnccl.so.2 /usr/local/cuda/lib/libnccl.so.2 && \
    ln -s /usr/include/nccl.h /usr/local/cuda/include/nccl.h

# Install bazel
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list && \
    curl https://bazel.build/bazel-release.pub.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y bazel

# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
RUN echo "startup --batch" >>/etc/bazel.bazelrc
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/etc/bazel.bazelrc

# Configure the build for our CUDA configuration.
ENV CI_BUILD_PYTHON python3
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV TF_NEED_CUDA 1
ENV TF_NEED_TENSORRT 1
ENV TF_CUDA_COMPUTE_CAPABILITIES=3.5,5.2,6.0,6.1,7.0
ENV TF_CUDA_VERSION=10.0
ENV TF_CUDNN_VERSION=7

# NCCL 2.x
ENV TF_NCCL_VERSION=2

ENV GOSU_VERSION 1.11
RUN set -eux; \
# save list of currently installed packages for later so we can clean up
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates wget; \
	if ! command -v gpg; then \
		apt-get install -y --no-install-recommends gnupg2 dirmngr; \
	fi; \
	rm -rf /var/lib/apt/lists/*; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true

RUN apt-get update -y && apt-get install -y --no-install-recommends \
        curl \
        git \
        rsync \
        wget \
	sudo \
        && rm -rf /var/lib/apt/lists/*

COPY pip_install_commands /tmp/pip_install_commands
RUN bash /tmp/pip_install_commands

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:"${LD_LIBRARY_PATH:-.}"
ENV PATH=/usr/local/cuda/bin:"${PATH}"

_DOCKERFILE_EOF_

touch ._prepare_and_await.sh && chmod a+x $_

cat <<'_ENTRYPOINT_EOF_' | tee ._prepare_and_await.sh
#!/bin/bash

set -eux -o pipefail

declare -xr CONTAINER_USER_ID
declare -xr CONTAINER_USER_NAME

echo "Starting with UID : ${CONTAINER_USER_ID}"
useradd --shell /bin/bash \
	-u "${CONTAINER_USER_ID}" -o -c "" \
	-m "${CONTAINER_USER_NAME}"

echo "${CONTAINER_USER_NAME}:${CONTAINER_USER_NAME}" | chpasswd
usermod -aG sudo ${CONTAINER_USER_NAME}
mkdir -p /etc/sudoers.d
echo "${CONTAINER_USER_NAME} ALL=(ALL) NOPASSWD: ALL" \
     > "/etc/sudoers.d/${CONTAINER_USER_NAME}"

export HOME=/home/"${CONTAINER_USER_NAME}"
chmod a+w /home/"${CONTAINER_USER_NAME}"
chown "${CONTAINER_USER_NAME}" /home/"${CONTAINER_USER_NAME}"

# exec /usr/local/bin/gosu "${CONTAINER_USER_NAME}" /bin/bash $@
sleep infinity
_ENTRYPOINT_EOF_

# Create build directories shared by host and container
mkdir -p /workspace/build_cache/tensorflow && pushd $_
sudo mkdir -p cache output
popd
sudo chown -R "${USER}" /workspace/build_cache/tensorflow
sudo ln -sfn /workspace/build_cache/tensorflow /tf_build

docker rm -f tensorflow-builder-env &>/dev/null || true

nvidia-docker run -d \
	      --env CONTAINER_USER_NAME=tensorflow \
	      --env CONTAINER_USER_ID="$(id -u)" \
	      --volume "${_bsd_}":/workspace \
	      --volume /tf_build:/tf_build \
	      --workdir /workspace \
	      --name tensorflow-builder-env \
	      tensorflow-builder:base \
	      /workspace/._prepare_and_await.sh

# This file is meant to be source'd
cat <<'_BUILD_TENSORFLOW_EOF_' | tee SOURCE_ME_TO_BUILD_TENSORFLOW

function bazel-build {
    sudo ln -fsn /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1
    tensorflow/tools/ci_build/builds/configured GPU

    bazel \
	--output_user_root=/tf_build/output \
	build \
	-c opt \
	--copt=-mavx \
	--config=cuda \
	$@

    sudo rm /usr/local/cuda/lib64/stubs/libcuda.so.1
}

function bazel-build-tensorflow-python {
    bazel-build tensorflow/tools/pip_package:build_pip_package
    mkdir -p /workspace/wheelhouse
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /workspace/wheelhouse
}

_BUILD_TENSORFLOW_EOF_

cat <<_RUN_BUILD_INST_EOF_
==========================================
Please run your build with this command

docker exec -it tensorflow-builder-env /usr/local/bin/gosu tensorflow bash
==========================================
_RUN_BUILD_INST_EOF_

function docker_exec {
    docker exec -it tensorflow-builder-env /usr/local/bin/gosu tensorflow $@
}

printf "Waiting for a while until things are settled ... "
sleep 7
printf "done\n"

docker_exec sudo ln -sfn /usr/bin/python3 /usr/bin/python
docker_exec bash
