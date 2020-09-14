#!/bin/bash
#
# Compile script for Spectrum kernel
# Copyright (C) 2020-2021 Adithya R.
# Copyright (C) 2022 Edgars C.

SECONDS=0 # builtin bash timer
ZIPNAME="Spectrum-$(date '+%Y%m%d-%H%M').zip"
COMPILER_DIR="$HOME/proton-clang"
AK3_DIR="$HOME/AnyKernel3"
DEFCONFIG="cust_defconfig"

export PATH="$COMPILER_DIR/bin:$PATH"

if ! [ -d "$COMPILER_DIR" ]; then
echo "Proton clang not found! Cloning to $COMPILER_DIR..."
if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang $COMPILER_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

export KBUILD_BUILD_USER=Edgars Cirulis
export KBUILD_BUILD_HOST=linux

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ] && [ -f "out/arch/arm64/boot/dtb.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone -q https://github.com/Spectrum-Kernel/AnyKernel3 -b miatoll; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
cp out/arch/arm64/boot/dtb.img AnyKernel3

rm -f *zip
cd AnyKernel3
git checkout master &> /dev/null
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
curl --upload-file $ZIPNAME http://transfer.sh/$ZIPNAME; echo
else
echo -e "\nCompilation failed!"
exit 1
fi
