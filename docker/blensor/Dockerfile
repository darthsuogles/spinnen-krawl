FROM ubuntu:18.04

RUN apt-get update && \
	apt-get install -y \
		curl \
		bzip2 \
		libfreetype6 \
		libgl1-mesa-dev \
		libglu1-mesa \
        libtiff-dev \
        libpng-dev \
        libjpeg-dev \
		libxi6 \
        libopenimageio-dev \
		libxrender1 \
        && \
	rm -rf /var/lib/apt/lists/*

ENV BLENDER_MAJOR=2.79 \
    BLENDER_VERSION=2.79 \
    SENSOR_EXT_VERSION=1.0.18-RC8 \
    SENSOR_EXT_TARBALL=blensor_1.0.18-RC8_x64.tbz

WORKDIR /blensor
RUN curl -LO https://blensor-downloads.hosted-secure.com/${SENSOR_EXT_TARBALL}
RUN mkdir -p prebuilt \
    && tar -jxf ${SENSOR_EXT_TARBALL} -C prebuilt --strip-components=1 \
    && rm -f ${SENSOR_EXT_TARBALL} \
    && ls prebuilt

# Needs OpenGL 2.1+ to run, maybe better off with nvidia-docker
# https://github.com/openai/gym/issues/509#issuecomment-291016862
RUN apt-get update && \
	apt-get install -y \
        libjemalloc-dev \
        mesa-utils \
        libgl1-mesa-glx \
        && \
	rm -rf /var/lib/apt/lists/*

VOLUME /media
ENTRYPOINT ["/blensor/prebuilt/blender"]
