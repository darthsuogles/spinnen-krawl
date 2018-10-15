#!/bin/bash

set -eu -o pipefail

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat <<_SCRIPT_LOCATION_WARNING_EOF_
==========================================
Please make sure this script is located 
under the root directory of tensorflow.
==========================================
_SCRIPT_LOCATION_WARNING_EOF_

docker pull tensorflow/tensorflow:nightly-devel-gpu-py3

nvidia-docker build "$(mktemp -d)" \
	      -t tensorflow-builder:base \
	      -f -<<'_DOCKERFILE_EOF_'
FROM tensorflow/tensorflow:nightly-devel-gpu-py3	      

ENV GOSU_VERSION 1.10
RUN set -ex; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu nobody true

RUN apt-get update -y && apt-get install -y --no-install-recommends \
        curl \
        git \
        rsync \
        wget \
	sudo \
        && rm -rf /var/lib/apt/lists/*
	      
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


mkdir -p "${_bsd_}/._tf_build_cache"

nvidia-docker run -d \
	      --env CONTAINER_USER_NAME=tensorflow \
	      --env CONTAINER_USER_ID="$(id -u)" \
	      --volume "${_bsd_}":/workspace \
	      --volume "${_bsd_}/._tf_build_cache":/tf_build_cache \
	      --workdir /workspace \
	      --name tensorflow-builder-env \
	      tensorflow-builder:base \
	      /workspace/._prepare_and_await.sh


touch ._build_tensorflow_impl.sh && chmod +x $_

cat <<'_BUILD_TENSORFLOW_EOF_' | tee ._build_tensorflow_impl.sh
#!/bin/bash

set -eu -o pipefail

sudo ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1
export LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:"${LD_LIBRARY_PATH:-.}"

tensorflow/tools/ci_build/builds/configured GPU
bazel build -c opt --copt=-mavx --config=cuda \
      --disk_cache=/tf_build_cache \
      --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
      tensorflow/tools/pip_package:build_pip_package

sudo rm /usr/local/cuda/lib64/stubs/libcuda.so.1

bazel-bin/tensorflow/tools/pip_package/build_pip_package /workspace/pip
pip --no-cache-dir install --upgrade /workspace/pip/tensorflow-*.whl
rm -rf /root/.cache

_BUILD_TENSORFLOW_EOF_

cat <<_RUN_BUILD_INST_EOF_
==========================================
Please run your build with this command

docker exec -it tensorflow-builder-env /usr/local/bin/gosu tensorflow bash
==========================================
_RUN_BUILD_INST_EOF_
