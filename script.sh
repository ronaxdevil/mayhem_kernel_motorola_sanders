#!/bin/bash

#set -e

DATE_POSTFIX=$(date +"%Y%m%d")

## Copy this script inside the kernel directory
KERNEL_DIR=$PWD
KERNEL_TOOLCHAIN=$PWD/../../prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
CLANG_TOOLCHAIN=$PWD/../../prebuilts-master/clang/host/linux-x86/clang-5407736/bin/clang-9
KERNEL_DEFCONFIG=sanders_defconfig
DTBTOOL=$KERNEL_DIR/tools/
JOBS=16
ZIP_DIR=$KERNEL_DIR/zip/
KERNEL=MAYHEM-KERNEL
TYPE=HMP-OC
RELEASE=DOOMSDAY
FINAL_KERNEL_ZIP=$KERNEL-$TYPE-$RELEASE-$DATE_POSTFIX.zip
# Speed up build process
MAKE="./makeparallel"

BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
#red
R='\033[05;31m'
#purple
P='\e[0;35m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e  "$P // Setting up Toolchain //"
export CROSS_COMPILE=$KERNEL_TOOLCHAIN
export ARCH=arm64
export SUBARCH=arm64

echo -e  "$R // Cleaning up //"
make clean && make mrproper && rm -rf out/

echo -e "$cyan // defconfig is set to $KERNEL_DEFCONFIG //"
echo -e "$blue***********************************************"
echo -e "$R          BUILDING MAYHEM-KERNEL          "
echo -e "***********************************************$nocol"
echo -e "$blue***********************************************"
echo -e "$R             DOOMSDAY IS HERE             "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG O=out
make -j$JOBS CC=$CLANG_TOOLCHAIN CLANG_TRIPLE=aarch64-linux-gnu- O=out

echo -e "$blue***********************************************"
echo -e "$R          Generating DT image          "
echo -e "***********************************************$nocol"
$DTBTOOL/dtbToolCM -2 -o $KERNEL_DIR/out/arch/arm64/boot/dtb -s 2048 -p $KERNEL_DIR/out/scripts/dtc/ $KERNEL_DIR/out/arch/arm64/boot/dts/qcom/

echo -e "$R // Verify Image.gz & dtb //"
ls $KERNEL_DIR/out/arch/arm64/boot/Image.gz
ls $KERNEL_DIR/out/arch/arm64/boot/dtb

echo -e "$R // Verifying zip Directory //"
ls $ZIP_DIR
echo "// Removing leftovers //"
rm -rf $ZIP_DIR/dtb
rm -rf $ZIP_DIR/Image.gz
rm -rf $ZIP_DIR/$FINAL_KERNEL_ZIP

echo "**** Copying Image.gz ****"
cp $KERNEL_DIR/out/arch/arm64/boot/Image.gz $ZIP_DIR/
echo "**** Copying dtb ****"
cp $KERNEL_DIR/out/arch/arm64/boot/dtb $ZIP_DIR/
echo "**** Copying modules ****"
mkdir -p zip/modules/vendor/lib/modules
[ -e "$KERNEL_DIR/out/drivers/char/rdbg.ko" ] && cp $KERNEL_DIR/out/drivers/char/rdbg.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/media/usb/gspca/gspca_main.ko" ] && cp $KERNEL_DIR/out/drivers/media/usb/gspca/gspca_main.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/drivers/misc/moto-dtv-fc8300/isdbt.ko" ] && cp $KERNEL_DIR/out/drivers/misc/moto-dtv-fc8300/isdbt.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/drivers/spi/spidev.ko" ] && cp $KERNEL_DIR/out/drivers/spi/spidev.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/drivers/video/backlight/backlight.ko" ] && cp $KERNEL_DIR/out/drivers/video/backlight/backlight.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/crypto/ansi_cprng.ko" ] && cp $KERNEL_DIR/out/crypto/ansi_cprng.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/drivers/video/backlight/generic_bl.ko" ] && cp $KERNEL_DIR/out/drivers/video/backlight/generic_bl.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/drivers/video/backlight/lcd.ko" ] && cp $KERNEL_DIR/out/drivers/video/backlight/lcd.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/net/bridge/br_netfilter.ko" ] && cp $KERNEL_DIR/out/net/bridge/br_netfilter.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/drivers/mmc/card/mmc_test.ko" ] && cp $KERNEL_DIR/out/drivers/mmc/card/mmc_test.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/drivers/input/evbug.ko" ] && cp $KERNEL_DIR/out/drivers/input/evbug.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."
[ -e "$KERNEL_DIR/out/drivers/usb/gadget/udc/dummy_hcd.ko" ] && cp $KERNEL_DIR/out/drivers/usb/gadget/udc/dummy_hcd.ko $ZIP_DIR/modules/vendor/lib/modules || echo "module not found..."

echo "**** Time to zip up! ****"
cd $ZIP_DIR/
zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
cp $KERNEL_DIR/zip/$FINAL_KERNEL_ZIP /home/ubuntu/$FINAL_KERNEL_ZIP

echo -e "$yellow // Build Successfull  //"
cd $KERNEL_DIR
rm -rf arch/arm64/boot/dtb
rm -rf $ZIP_DIR/$FINAL_KERNEL_ZIP
rm -rf zip/Image.gz
rm -rf zip/dtb
rm -rf zip/modules/vendor/lib/modules/*.ko
rm -rf $KERNEL_DIR/out/
rm -rf zip/modules/vendor/lib/modules

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
