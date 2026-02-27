#!/bin/bash
set -e

# Configuration
IMAGE_NAME=${IMAGE_NAME:-"esp32s3-linux"}
BUILD_OUTPUT_DIR="$(pwd)/build-output"
SOURCES_DIR="$(pwd)/sources"
TOOLCHAIN_DIR="$(pwd)/toolchain"

# Ensure directories exist
mkdir -p "$BUILD_OUTPUT_DIR/release"
mkdir -p "$SOURCES_DIR"
mkdir -p "$TOOLCHAIN_DIR"

show_help() {
    echo "Usage: $0 [options] [targets]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -c, --clean   Clean build artifacts"
    echo ""
    echo "Targets:"
    echo "  all           Build everything (default)"
    echo "  dynconfig     Build xtensa-dynconfig"
    echo "  hosted        Build esp-hosted firmware"
    echo "  buildroot     Build buildroot Linux"
    echo ""
    echo "Example:"
    echo "  $0 dynconfig buildroot"
}

# Parse arguments
TARGETS=()
CLEAN=false

if [ $# -eq 0 ]; then
    TARGETS=("all")
else
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help|help)
                show_help
                exit 0
                ;;
            -c|--clean|clean)
                CLEAN=true
                shift
                ;;
            all|dynconfig|hosted|buildroot)
                TARGETS+=("$1")
                shift
                ;;
            *)
                echo "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
fi

if [ "$CLEAN" = true ]; then
    echo "Cleaning build artifacts..."
    docker run --rm \
      -v "$BUILD_OUTPUT_DIR":/app/build-output \
      -u root \
      "$IMAGE_NAME" /bin/bash -c "rm -rf /app/build-output/* /app/build-output/.* 2>/dev/null || true"
    mkdir -p "$BUILD_OUTPUT_DIR/release"
    echo "Clean complete."
    if [ ${#TARGETS[@]} -eq 0 ]; then
        exit 0
    fi
fi

# Expand 'all' to specific targets
FINAL_TARGETS=()
HAS_ALL=false
for t in "${TARGETS[@]}"; do
    if [ "$t" == "all" ]; then
        HAS_ALL=true
        break
    fi
done

if [ "$HAS_ALL" = true ]; then
    FINAL_TARGETS=("dynconfig" "hosted" "buildroot")
else
    FINAL_TARGETS=("${TARGETS[@]}")
fi

if [ ${#FINAL_TARGETS[@]} -eq 0 ]; then
    exit 0
fi

# Prepare the build script to run inside the container
INSIDE_SCRIPT_PATH="$BUILD_OUTPUT_DIR/build_inside.sh"
cat <<'EOF' > "$INSIDE_SCRIPT_PATH"
#!/bin/bash
set -e

echo "Adjusting permissions..."
chown -R esp32:esp32 /app/build-output /app/sources
EOF

for target in "${FINAL_TARGETS[@]}"; do
    case $target in
        dynconfig)
            cat <<'EOF' >> "$INSIDE_SCRIPT_PATH"
echo "--- BUILDING DYNCONFIG ---"
su esp32 -c 'make -C /app/sources/xtensa-dynconfig ORIG=1 CONF_DIR=/app/sources/config-esp32s3 esp32s3.so'
EOF
            ;;
        hosted)
            cat <<'EOF' >> "$INSIDE_SCRIPT_PATH"
echo "--- BUILDING ESP-HOSTED ---"
su esp32 -c '
  export PIP_BREAK_SYSTEM_PACKAGES=1
  export IDF_PATH=/app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/esp-idf
  cd /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver
  if [ ! -d "esp-idf" ] || [ ! -f "esp-idf/export.sh" ]; then
    cmake .
  fi
  # Always ensure wireless libraries are replaced, as cmake . might be skipped
  for arch in esp32 esp32c3 esp32s2 esp32s3; do
    if [ -d "lib/$arch" ]; then
      cp lib/$arch/*.a esp-idf/components/esp_wifi/lib/$arch/
    fi
  done
  cd esp-idf
  if [ -f "requirements.txt" ]; then
    sed -i "/gdbgui/d" requirements.txt
  fi
  export IDF_GITHUB_ASSETS="dl.espressif.com/github_assets"
  ./install.sh esp32s3
  . ./export.sh
  python -m pip install "setuptools<70"
  cd ../network_adapter
  idf.py set-target esp32s3
  cp sdkconfig.defaults.esp32s3 sdkconfig
  idf.py build
'
EOF
            ;;
        buildroot)
            cat <<'EOF' >> "$INSIDE_SCRIPT_PATH"
echo "--- BUILDING BUILDROOT ---"
su esp32 -c '
  cd /app/sources/buildroot
  make O=/app/build-output esp32s3_devkit_c1_8m_defconfig
  /app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_PATH /app/toolchain/xtensa-esp32s3-linux-uclibcfdpic
  /app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_PREFIX "\$(ARCH)-esp32s3-linux-uclibcfdpic"
  /app/sources/buildroot/utils/config --file /app/build-output/.config --set-str TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX "\$(ARCH)-esp32s3-linux-uclibcfdpic"
  /app/sources/buildroot/utils/config --file /app/build-output/.config --set-val BR2_JLEVEL $(nproc)
  
  make O=/app/build-output source
  rm -rf /app/build-output/target
  make O=/app/build-output
'
EOF
            ;;
    esac
done

cat <<'EOF' >> "$INSIDE_SCRIPT_PATH"
echo "--- VERIFYING ARTIFACTS ---"
EOF

for target in "${FINAL_TARGETS[@]}"; do
    case $target in
        dynconfig)
            echo "ls -lh /app/sources/xtensa-dynconfig/esp32s3.so" >> "$INSIDE_SCRIPT_PATH"
            ;;
        hosted)
            cat <<'EOF' >> "$INSIDE_SCRIPT_PATH"
ls -lh /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/bootloader/bootloader.bin
ls -lh /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/partition_table/partition-table.bin
ls -lh /app/sources/esp-hosted/esp_hosted_ng/esp/esp_driver/network_adapter/build/network_adapter.bin
EOF
            ;;
        buildroot)
            cat <<'EOF' >> "$INSIDE_SCRIPT_PATH"
ls -lh /app/build-output/images/etc.jffs2
ls -lh /app/build-output/images/xipImage
ls -lh /app/build-output/images/rootfs.cramfs
EOF
            ;;
    esac
done

# Run the constructed script inside the container
docker run --rm \
  -v "$SOURCES_DIR":/app/sources \
  -v "$TOOLCHAIN_DIR":/app/toolchain \
  -v "$BUILD_OUTPUT_DIR":/app/build-output \
  -u root \
  "$IMAGE_NAME" /bin/bash /app/build-output/build_inside.sh

# Cleanup the temporary script
rm "$INSIDE_SCRIPT_PATH"
