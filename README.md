# ESP32-S3 Linux Build Environment

This repository provides a Docker-based build environment for running Linux on the ESP32-S3.

## Initial Setup

Before building or entering the environment for the first time:

1. **Prepare the Host:** This script downloads the pre-built toolchain from the GitHub releases and performs shallow clones of the required source repositories (Buildroot, Kernel, etc.) directly to your host's filesystem.
   ```bash
   bash prepare_host.sh
   ```

2. **Build the Docker Image:** Build the lean Ubuntu 24.04-based environment.
   ```bash
   docker build -t esp32s3-linux .
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

### Common Build Commands (Inside the Container)

- **Buildroot Configuration:**
  ```bash
  cd /app/sources/buildroot
  make O=/app/build-output menuconfig
  ```

- **Kernel Configuration:**
  ```bash
  cd /app/sources/buildroot
  make O=/app/build-output linux-menuconfig
  ```

- **Full Build:**
  ```bash
  cd /app/sources/buildroot
  make O=/app/build-output
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
