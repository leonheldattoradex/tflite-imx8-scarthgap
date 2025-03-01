FROM torizon/debian-imx8:stable-rc AS base

RUN apt-get -y update && apt-get install -y \
  autoconf \
  automake \
  build-essential \
  cmake \
  curl \
  g++ \
  gcc \
  gfortran \
  git \
  imx-gpu-viv-wayland-dev \
  libffi-dev \
  libflatbuffers-dev \
  libjpeg-dev \
  libssl-dev \
  libtool \
  openssl \
  patchelf \
  python3 \
  python3-dev \
  python3-numpy \
  python3-pip \
  python3-pybind11 \
  python3-setuptools \
  python3-wheel \
  unzip \
  wget \
  zlib1g \
  zlib1g-dev \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY recipes /build

RUN ./tim-vx_1.2.2.bash && ./tensorflow-lite_2.16.2.bash && ./tensorflow-lite-vx-delegate_2.16.2.bash && rm -rf tflite-build tflite-vx-delegate-build tim-vx-build

