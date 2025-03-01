#!/bin/bash
set -e
set -x

INSTALL_PREFIX="/usr"
PYTHON_SITEPACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])")
WORKDIR="$PWD/tflite-build"
MODEL_URL="https://storage.googleapis.com/download.tensorflow.org/models/mobilenet_v1_2018_08_02/mobilenet_v1_1.0_224_quant.tgz"
MODEL_SHA256="d32432d28673a936b2d6281ab0600c71cf7226dfe4cdcef3012555f691744166"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

git clone https://github.com/nxp-imx/tensorflow-imx.git -b lf-6.6.36_2.1.0
cd tensorflow-imx
git checkout ad08fc3b5af2b2a144cda89a83fdb7252d1d75b6
git config --global --add safe.directory /build/tflite-build/tensorflow-imx

wget "$MODEL_URL"
echo "$MODEL_SHA256  mobilenet_v1_1.0_224_quant.tgz" | sha256sum -c
tar xzf mobilenet_v1_1.0_224_quant.tgz --no-same-owner

mkdir -p buildd
cd buildd
cmake ../tensorflow/lite \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DFETCHCONTENT_FULLY_DISCONNECTED=OFF \
    -DTFLITE_EVAL_TOOLS=ON \
    -DTFLITE_BUILD_SHARED_LIB=ON \
    -DTFLITE_ENABLE_NNAPI=OFF \
    -DTFLITE_ENABLE_RUY=ON \
    -DTFLITE_ENABLE_XNNPACK=ON \
    -DTFLITE_ENABLE_EXTERNAL_DELEGATE=ON

make -j$(nproc) benchmark_model label_image

CI_BUILD_PYTHON=python3 BUILD_NUM_JOBS=$(nproc) \
    ../tensorflow/lite/tools/pip_package/build_pip_package_with_cmake.sh

mkdir -p "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/include/tensorflow/lite"

find . -name 'libtensorflow-lite*.so*' -exec install -Dm755 {} "$INSTALL_PREFIX/lib/aarch64-linux-gnu" \;

cd ..

cp --parents $(find tensorflow/lite -name '*.h*') "$INSTALL_PREFIX/include/tensorflow/lite"
mkdir -p "$INSTALL_PREFIX/include/tensorflow/core/public"
cp tensorflow/core/public/version.h "$INSTALL_PREFIX/include/tensorflow/core/public"
cp tensorflow/core/platform/ctstring_internal.h "$INSTALL_PREFIX/include/tensorflow/core/platform"
mkdir -p "$INSTALL_PREFIX/include/tsl/platform"
cp third_party/xla/third_party/tsl/tsl/platform/ctstring_internal.h "$INSTALL_PREFIX/include/tsl/platform"

EXAMPLES_DIR="$INSTALL_PREFIX/share/tensorflow-lite/examples"
mkdir -p "$EXAMPLES_DIR"
install -m755 buildd/examples/label_image/label_image "$EXAMPLES_DIR"
install -m755 buildd/tools/benchmark/benchmark_model "$EXAMPLES_DIR"
cp tensorflow/lite/examples/label_image/testdata/grace_hopper.bmp "$EXAMPLES_DIR"
cp tensorflow/lite/java/ovic/src/testdata/labels.txt "$EXAMPLES_DIR"
cp mobilenet_v1_1.0_224_quant.tflite "$EXAMPLES_DIR"

pip3 install --break-system-packages --no-cache-dir ./tensorflow/lite/tools/pip_package/gen/tflite_pip/python3/dist/tflite_runtime*.whl

ldconfig

echo "TensorFlow Lite installation completed"
echo "Libraries:  $INSTALL_PREFIX/lib"
echo "Headers:    $INSTALL_PREFIX/include/tensorflow"
echo "Examples:   $EXAMPLES_DIR"
