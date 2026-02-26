#!/bin/bash

# Ensure build-output exists so it's owned by the user if Docker creates it
mkdir -p build-output

# Run container with volume mappings
docker run -it --rm \
    -v $(pwd)/sources:/app/sources \
    -v $(pwd)/toolchain:/app/toolchain \
    -v $(pwd)/build-output:/app/build-output \
    -u root \
    esp32s3-linux /bin/bash -c "
        # Ensure correct permissions
        chown -R esp32:esp32 /app/build-output /app/sources
        
        # Build dynconfig .so if it doesn't exist
        if [ ! -f /app/sources/xtensa-dynconfig/esp32s3.so ]; then
            su esp32 -c 'make -C /app/sources/xtensa-dynconfig ORIG=1 CONF_DIR=/app/sources/config-esp32s3 esp32s3.so'
        fi

        echo 'Environment ready. You can now build ESP-Hosted or Buildroot.'
        echo 'Example for ESP-Hosted:'
        echo '  cd /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/esp-idf && . ./export.sh && cd ../network_adapter && idf.py build'
        echo 'Example for Buildroot:'
        echo '  cd /app/sources/buildroot && make O=/app/build-output'
        
        su esp32"
