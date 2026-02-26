# ESP32-S3 Linux Build Environment

This repository provides a Docker-based build environment for running Linux on the ESP32-S3.

## Initial Setup

Before building or entering the environment for the first time:

1. **Prepare the Host:**
   ```bash
   bash prepare_host.sh
   ```

2. **Build the Docker Image:**
   ```bash
   docker build -t esp32s3-linux .
   ```

## Flash Offsets

The build produces the following artifacts for flashing to the ESP32-S3:

- `0x0000`   `bootloader.bin`
- `0x8000`   `partition-table.bin`
- `0x10000`  `network_adapter.bin`
- `0xb0000`  `etc.jffs2`
- `0x120000` `xipImage`
- `0x480000` `rootfs.cramfs`

## Interactive Development

To enter the build environment:

```bash
bash enter_env.sh
```

### Building ESP-Hosted (Inside the Container)

```bash
cd /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver
git clone --recursive https://github.com/espressif/esp-idf.git -b v5.1 --depth 1 esp-idf
cd esp-idf
./install.sh esp32s3
. ./export.sh
cd ../network_adapter
idf.py set-target esp32s3
cp sdkconfig.defaults.esp32s3 sdkconfig
idf.py build
```

### Building Buildroot (Inside the Container)

```bash
cd /app/sources/buildroot
make O=/app/build-output esp32s3_defconfig
# The toolchain path and prefix are automatically set in the CI, 
# for local builds ensure they match your mount points.
make O=/app/build-output
```

## GitHub Actions

- **Toolchain Build:** Manually triggered to build the toolchain.
- **Main Build:** Manually triggered to perform a full compilation and publish artifacts with flash offsets.
