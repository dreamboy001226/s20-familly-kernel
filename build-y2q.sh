#!/bin/bash

set -e

KERNEL_DIR="$(pwd)"
OUT_DIR="$KERNEL_DIR/out"
ANYKERNEL_DIR="$KERNEL_DIR/AnyKernel3"
GCC_PATH="/usr/bin/"
LLD_PATH="/usr/bin/"
KERNEL_NAME="Astro_kernel-"
MAKE="./makeparallel"
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

# Install clang toolchain
mkdir -p clang
cd clang || exit 1
wget -q https://github.com/ZyCromerZ/Clang/releases/download/21.0.0git-20250228-release/Clang-21.0.0git-20250228.tar.gz -O clang.tar.gz
tar -xf clang.tar.gz
cd "$KERNEL_DIR" || exit 1
PATH="${KERNEL_DIR}/clang/bin:$PATH"

# Cross compile options
MAKE_OPT=()
MAKE_OPT+=(CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-)

# Clean previous outputs
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
rm -f "$ANYKERNEL_DIR"/dtb "$ANYKERNEL_DIR"/Image "$ANYKERNEL_DIR"/dtbo.img
rm -f .version .local

# Kernel configuration
make O="$OUT_DIR" ARCH=arm64 LLVM=1 LLVM_IAS=1 "${MAKE_OPT[@]}" \
    vendor/kona-not_defconfig vendor/samsung/y2q.config vendor/debugfs.config

echo "*****************************************"
echo "********** Kernel Build Start ***********"
echo "*****************************************"

# Build DTBs
make -j"$(nproc)" O="$OUT_DIR" ARCH=arm64 LLVM=1 LLVM_IAS=1 "${MAKE_OPT[@]}" dtbs
DTB_OUT="$OUT_DIR/arch/arm64/boot/dts/vendor/qcom"
if ls "$DTB_OUT"/*.dtb 1> /dev/null 2>&1; then
    cat "$DTB_OUT"/*.dtb > "$ANYKERNEL_DIR/dtb"
fi

# Build Kernel Image
make -j"$(nproc)" O="$OUT_DIR" ARCH=arm64 LLVM=1 LLVM_IAS=1 "${MAKE_OPT[@]}" Image
IMAGE="$OUT_DIR/arch/arm64/boot/Image"

echo "**Build outputs**"
ls "$OUT_DIR/arch/arm64/boot" || true
echo "**Build outputs**"

cp "$IMAGE" "$ANYKERNEL_DIR/Image"

# Package into zip
cd "$ANYKERNEL_DIR"
rm -f *.zip *.img Image dtb
zip -r9 "${KERNEL_NAME}$(date +"%Y%m%d")+y2q.zip" . -x "*.git*" -x "README.md"
