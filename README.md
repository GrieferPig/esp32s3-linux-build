# ESP32-S3 Linux Build Environment

This repository provides a Docker-based build environment for compiling Linux and the required firmware (bootloader, partition table, and network adapter) for the ESP32-S3.

## Initial Setup

Before building or entering the environment for the first time:

1. **Prepare the Host:** This script downloads the pre-built toolchain from the GitHub releases and performs shallow clones of the required source repositories (Buildroot, Kernel, ESP-Hosted, etc.) directly to your host's filesystem.

   ```bash
   bash prepare_host.sh
   ```

2. **Build the Docker Image:** Build the lean Ubuntu 24.04-based environment.

   ```bash
   docker build -t esp32s3-linux .
   ```

## Automated Test Build

To run an automated full build process that compiles both ESP-Hosted and Buildroot, and validates artifact generation, use the provided script:

```bash
bash build.sh
```

## Interactive Development

To enter the build environment with all local sources and the toolchain correctly mounted:

```bash
bash enter_env.sh
```

The script handles:

- Mounting `sources/`, `toolchain/`, and `build-output/`.
- Ensuring correct permissions for the `esp32` user.
- Building the `xtensa-dynconfig` library if missing.

### Manual Build Steps (Inside the Container)

Once inside the container, you can manually trigger the build processes:

#### 1. Build ESP-Hosted Firmware (Bootloader, Partition Table, Network Adapter)

This requires setting up the ESP-IDF environment. Note the requirement to bypass the system package warning for Python 3.12:

```bash
export PIP_BREAK_SYSTEM_PACKAGES=1
export IDF_PATH=/app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/esp-idf
cd /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver
cmake .
cd esp-idf
sed -i "/gdbgui/d" requirements.txt
export IDF_GITHUB_ASSETS="dl.espressif.com/github_assets"
./install.sh esp32s3
. ./export.sh
python -m pip install "setuptools<70"
cd ../network_adapter
idf.py set-target esp32s3
cp sdkconfig.defaults.esp32s3 sdkconfig
idf.py build
```

#### 2. Build Buildroot (Kernel, Rootfs, DTB)

```bash
cd /app/sources/buildroot
make O=/app/build-output esp32s3_defconfig
/app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_PATH /app/toolchain/xtensa-esp32s3-linux-uclibcfdpic
/app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_PREFIX "\$(ARCH)-esp32s3-linux-uclibcfdpic"
/app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX "\$(ARCH)-esp32s3-linux-uclibcfdpic"
/app/sources/buildroot/utils/config --file /app/build-output/.config --set-val BR2_JLEVEL 4

# Initialize sources
make O=/app/build-output source

# Final compilation
find /app/sources/buildroot /app/build-output -type f -exec touch {} + || true
rm -rf /app/build-output/target
make O=/app/build-output
```

### Configuration (Inside the Container)

- **Buildroot Menuconfig:**

  ```bash
  cd /app/sources/buildroot
  make O=/app/build-output menuconfig
  ```

- **Kernel Menuconfig:**

  ```bash
  cd /app/sources/buildroot
  make O=/app/build-output linux-menuconfig
  ```

## Expected Artifacts and Flash Offsets

Once the build is complete, you should find the following artifacts to be flashed to the ESP32-S3:

- **0x0000** - Bootloader: `/app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/bootloader/bootloader.bin`
- **0x8000** - Partition Table: `/app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/partition_table/partition-table.bin`
- **0x10000** - Network Adapter: `/app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/network_adapter.bin`
- **0xb0000** - JFFS2 Image: `/app/build-output/images/etc.jffs2`
- **0x120000** - Linux Kernel (XIP): `/app/build-output/images/xipImage`
- **0x480000** - CramFS RootFS: `/app/build-output/images/rootfs.cramfs`

## Flash command

```bash
esptool.py --chip esp32s3 -p /dev/ttyUSB0 -b 921600 --before default_reset --after hard_reset write_flash 0x0000 build/bootloader.bin 0x8000 build/partition-table.bin 0x10000 build/network_adapter.bin 0xb0000 build/etc.jffs2 0x120000 build/xipImage 0x480000 build/rootfs.cramfs
```

## GitHub Actions

- **Toolchain Build:** Manually triggered to build the `xtensa-esp32s3-linux-uclibcfdpic` toolchain and publish it as a release.
- **Main Build:** Manually triggered to perform a full Buildroot compilation using the latest environment and publish artifacts.

## File Structure

- `sources/`: Cloned source repositories (ignored by git).
- `toolchain/`: Downloaded toolchain (ignored by git).
- `build-output/`: Build artifacts and intermediate files (ignored by git).
- `Dockerfile`: Lean environment definition.
- `prepare_host.sh`: Host environment setup script.
- `enter_env.sh`: Interactive environment entry script.
- `test_build.sh`: Automated full-build verification script.
