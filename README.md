# ESP32-S3 Linux Build Environment

This repository provides a Docker-based build environment for running Linux on the ESP32-S3.

## Building Locally

To build the environment and extract the artifacts:

```bash
# Build the Docker image
docker build -t esp32s3-linux .

# Extract artifacts to build/ and configs to root
bash extract_artifacts.sh
```
## Flashing

To flash the artifacts to your ESP32-S3, you can use `esptool.py`. Replace `/dev/ttyUSB0` with your actual serial port:

```bash
esptool.py --chip esp32s3 -p /dev/ttyUSB0 -b 921600 \
  --before default_reset --after hard_reset write_flash \
  0x0000 build/bootloader.bin \
  0x8000 build/partition-table.bin \
  0x10000 build/network_adapter.bin \
  0x120000 build/xipImage \
  0x4b0000 build/etc.jffs2
```

Note: This build requires an ESP32-S3 with **8MB PSRAM** (e.g., N8R8 or N16R8).


## Interactive Configuration

To modify the build configurations interactively, enter the container:

```bash
docker run -it --rm esp32s3-linux /bin/bash
```

Inside the container, use the following commands:

- **Buildroot Configuration:**
  ```bash
  cd /app/build/buildroot
  make O=/app/build/build-buildroot-esp32s3 menuconfig
  ```

- **Kernel Configuration:**
  ```bash
  cd /app/build/buildroot
  make O=/app/build/build-buildroot-esp32s3 linux-menuconfig
  ```

## GitHub Actions

The repository includes a GitHub Action that automatically builds the image and creates a release with the following artifacts:
- Kernel (`xipImage`) and Device Tree (`.dtb`)
- RootFS images (`rootfs.cramfs`, `etc.jffs2`)
- Bootloader and Network Adapter binaries
- Full RootFS tarball
- Configuration files (`buildroot.config`, `kernel.config`, `crosstool-ng.config`)
