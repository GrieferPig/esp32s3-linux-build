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
