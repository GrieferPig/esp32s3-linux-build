#!/bin/bash

# Ensure build-output exists so it's owned by the user if Docker creates it
mkdir -p build-output

# Run container with volume mappings
docker run -it --rm 
    -v $(pwd)/sources:/app/sources 
    -v $(pwd)/toolchain:/app/toolchain 
    -v $(pwd)/build-output:/app/build-output 
    -v $(pwd)/buildroot.config:/app/sources/buildroot/.config 
    esp32s3-linux /bin/bash -c "
        # Build dynconfig .so if it doesn't exist
        if [ ! -f /app/sources/xtensa-dynconfig/esp32s3.so ]; then
            make -C /app/sources/xtensa-dynconfig ORIG=1 CONF_DIR=/app/sources/config-esp32s3 esp32s3.so
        fi
        /bin/bash"
