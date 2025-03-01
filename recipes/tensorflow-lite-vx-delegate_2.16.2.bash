#!/bin/bash
set -e
set -x

mkdir -p tflite-vx-delegate-build
cd tflite-vx-delegate-build

git clone https://github.com/nxp-imx/tflite-vx-delegate-imx.git -b lf-6.6.36_2.1.0 delegate-src
cd delegate-src
git checkout 6e1193cddabfab024fa36bdb90fcf7840821ec56
git apply /build/0001-Findtim-vx.cmake-Fix-LIBDIR-for-multilib-environment.patch
cd ..

git clone https://github.com/nxp-imx/tensorflow-imx.git -b lf-6.6.36_2.1.0 tfgit
cd tfgit
git checkout ad08fc3b5af2b2a144cda89a83fdb7252d1d75b6
cd ..

export CXXFLAGS="-fPIC"
export FC=""

mkdir -p buildd
cd buildd

cmake ../delegate-src \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DFETCHCONTENT_FULLY_DISCONNECTED=OFF \
    -DTIM_VX_INSTALL=/usr \
    -DFETCHCONTENT_SOURCE_DIR_TENSORFLOW=../tfgit \
    -DTFLITE_LIB_LOC=/usr/lib/$(uname -m)-linux-gnu/libtensorflow-lite.so

make -j$(nproc)

install -D -m 0755 libvx_delegate.so* /usr/lib/aarch64-linux-gnu
mkdir -p /usr/include/tensorflow-lite-vx-delegate
cp -r ../delegate-src/*.h /usr/include/tensorflow-lite-vx-delegate/
