#!/bin/bash

set -eu -o pipefail

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat <<_SCRIPT_LOCATION_WARNING_EOF_
==========================================
Please make sure this script is located
under the root directory of pytorch.
==========================================
_SCRIPT_LOCATION_WARNING_EOF_

declare -xr BASE_DOCKER_IMAGE="nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04"
# Don't pull the latest version unless absolutely have to
docker pull "${BASE_DOCKER_IMAGE}"

nvidia-docker build "$(mktemp -d)" \
	      --build-arg BASE_DOCKER_IMAGE="${BASE_DOCKER_IMAGE}" \
	      -t pytorch-builder:base \
	      -f -<<'_DOCKERFILE_EOF_'
ARG BASE_DOCKER_IMAGE
FROM ${BASE_DOCKER_IMAGE} AS OS_BASE_LAYER

RUN apt-get update && apt-get install -y --no-install-recommends \
         build-essential \
         cmake \
         git \
         curl \
         ca-certificates \
	 sudo \
         libjpeg-dev \
         libpng-dev &&\
     rm -rf /var/lib/apt/lists/*

FROM OS_BASE_LAYER AS CONDA_LAYER

ARG PYTHON_VERSION=3.7
ENV PYTHON_VERSION=${PYTHON_VERSION}

RUN curl -fsSL -o /tmp/miniconda.sh \
         -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x /tmp/miniconda.sh && \
    /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh

RUN /opt/conda/bin/conda install -y \
    python=$PYTHON_VERSION \
    numpy \
    pyyaml \
    scipy \
    ipython \
    cython \
    typing

RUN /opt/conda/bin/conda install -y -c intel \
    mkl \
    mkl-include \
    mkl-dnn

RUN /opt/conda/bin/conda install -y -c pytorch \
    magma-cuda100

RUN /opt/conda/bin/conda clean -ya

FROM CONDA_LAYER AS ENV_LAYER

RUN ln -fsn /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1

ENV LD_LIBRARY_PATH /usr/local/cuda/lib64/stubs:/usr/local/cuda/lib64:"${LD_LIBRARY_PATH}"
ENV PATH /usr/local/cuda/bin:/opt/conda/bin:"${PATH}"

ENV TORCH_CUDA_ARCH_LIST "3.5 5.2 6.0 6.1 7.0+PTX"
ENV TORCH_NVCC_FLAGS "-Xfatbin -compress-all"
ENV CMAKE_PREFIX_PATH /opt/conda

FROM ENV_LAYER AS RUNTIME_LAYER

ENV GOSU_VERSION 1.11
RUN set -ex; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	curl -fsSL -o /usr/local/bin/gosu \
	  -O "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	curl -fsSL -o /usr/local/bin/gosu.asc \
	  -O "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu nobody true

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

docker rm -f pytorch-builder-env &>/dev/null || true

nvidia-docker run -d \
	      --ipc host \
	      --env CONTAINER_USER_NAME=pytorch \
	      --env CONTAINER_USER_ID="$(id -u)" \
	      --volume "${_bsd_}":/workspace \
	      --volume /workspace/wheelhouse/pytorch:/wheelhouse \
	      --workdir /workspace \
	      --name pytorch-builder-env \
	      pytorch-builder:base \
	      /workspace/._prepare_and_await.sh

cat <<'_BUILD_PYTORCH_EOF_' | tee SOURCE_ME_TO_BUILD_PYTORCH

function build-pytorch {
    python setup.py bdist_wheel -d /wheelhouse
}

_BUILD_PYTORCH_EOF_

cat <<_RUN_BUILD_INST_EOF_
==========================================
For building wheels for distribution, check this
https://github.com/pytorch/builder/blob/master/wheel/build_wheel.sh
==========================================
_RUN_BUILD_INST_EOF_

printf "Wait for a while till things are settled ... "
sleep 7
printf "done\n"
docker exec -it pytorch-builder-env /usr/local/bin/gosu pytorch bash
