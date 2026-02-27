#!/bin/bash
set -e

# Configuration
REPO="GrieferPig/esp32s3-linux-build"
TOOLCHAIN_URL="https://github.com/${REPO}/releases/download/toolchain/xtensa-esp32s3-linux-uclibcfdpic.tar.gz"

echo "Creating directory structure..."
mkdir -p sources toolchain build-output

# Download Toolchain
if [ ! -d "toolchain/xtensa-esp32s3-linux-uclibcfdpic" ]; then
    echo "Downloading toolchain..."
    curl -L ${TOOLCHAIN_URL} | tar -xz -C toolchain/
else
    echo "Toolchain already exists."
fi

# Shallow Clones
echo "Cloning repositories..."

if [ ! -d "sources/xtensa-dynconfig" ]; then
    git clone https://github.com/jcmvbkbc/xtensa-dynconfig -b original --depth 1 sources/xtensa-dynconfig
fi

if [ ! -d "sources/config-esp32s3" ]; then
    git clone https://github.com/jcmvbkbc/config-esp32s3 --depth 1 sources/config-esp32s3
fi

if [ ! -d "sources/esp-hosted" ]; then
    git clone https://github.com/jcmvbkbc/esp-hosted -b ipc --recursive --depth 1 --shallow-submodules sources/esp-hosted
fi

if [ ! -d "sources/buildroot" ]; then
    git clone https://github.com/jcmvbkbc/buildroot -b xtensa-2025.08-fdpic --depth 1 sources/buildroot
fi

# Restructure config-esp32s3 to match xtensa-dynconfig Makefile expectation
if [ -d "sources/config-esp32s3" ] && [ ! -d "sources/config-esp32s3/esp32s3" ]; then
    echo "Restructuring config-esp32s3..."
    cd sources/config-esp32s3
    mkdir -p esp32s3
    mv binutils gcc gdb xtensa esp32s3/
    cd ../..
fi

echo "Host preparation complete."
