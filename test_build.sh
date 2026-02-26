#!/bin/bash

# Ensure idempotency
mkdir -p build-output/release

docker run --rm \
  -v $(pwd)/sources:/app/sources \
  -v $(pwd)/toolchain:/app/toolchain \
  -v $(pwd)/build-output:/app/build-output \
  -u root \
  esp32s3-linux /bin/bash -c "
    set -e
    chown -R esp32:esp32 /app/build-output /app/sources

    su esp32 -c 'make -C /app/sources/xtensa-dynconfig ORIG=1 CONF_DIR=/app/sources/config-esp32s3 esp32s3.so'

    su esp32 -c '
      export PIP_BREAK_SYSTEM_PACKAGES=1
      export IDF_PATH=/app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/esp-idf
      cd /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver
      cmake .
      cd esp-idf
      sed -i \"/gdbgui/d\" requirements.txt
      export IDF_GITHUB_ASSETS=\"dl.espressif.com/github_assets\"
      ./install.sh esp32s3
      . ./export.sh
      python -m pip install \"setuptools<70\"
      cd ../network_adapter
      idf.py set-target esp32s3
      cp sdkconfig.defaults.esp32s3 sdkconfig
      idf.py build
    '

    su esp32 -c '
      cd /app/sources/buildroot
      make O=/app/build-output esp32s3_defconfig
      /app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_PATH /app/toolchain/xtensa-esp32s3-linux-uclibcfdpic
      /app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_PREFIX \"\$(ARCH)-esp32s3-linux-uclibcfdpic\"
      /app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX \"\$(ARCH)-esp32s3-linux-uclibcfdpic\"
      /app/sources/buildroot/utils/config --file /app/build-output/.config --set-val BR2_JLEVEL 4
      
      make O=/app/build-output source
      find /app/sources/buildroot /app/build-output -type f -exec touch {} + || true
      rm -rf /app/build-output/target
      make O=/app/build-output
    '

    echo '--- VERIFYING ARTIFACTS ---'
    ls -lh /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/bootloader/bootloader.bin
    ls -lh /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/partition_table/partition-table.bin
    ls -lh /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/network_adapter.bin
    ls -lh /app/build-output/images/etc.jffs2
    ls -lh /app/build-output/images/xipImage
    ls -lh /app/build-output/images/rootfs.cramfs
"