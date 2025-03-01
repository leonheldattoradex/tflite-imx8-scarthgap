#!/bin/bash
set -e
set -x

REPO_URL="https://github.com/nxp-imx/tim-vx-imx.git"
BRANCH="lf-6.6.36_2.1.0"
COMMIT="cada8e8bf5c91b002e793eda852b096c1b777e4b"

BUILD_DIR="$PWD/tim-vx-build"
mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR"

git clone "$REPO_URL" --branch "$BRANCH" --depth 1 tim-vx-src
cd tim-vx-src
git checkout "$COMMIT"

mkdir -p buildd
cd buildd
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DTIM_VX_ENABLE_TEST=OFF \
    -DTIM_VX_USE_EXTERNAL_OVXLIB=OFF \
    -DCONFIG=YOCTO

make -j$(nproc)
make install

ldconfig

popd
echo "TIM-VX successfully installed to system directories"
echo "Headers:    /usr/include"
echo "Libraries:  /usr/lib"
