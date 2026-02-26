FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    unzip \
    rsync \
    wget \
    bzip2 \
    cpio \
    bc \
    gperf \
    bison \
    flex \
    texinfo \
    help2man \
    gawk \
    libssl-dev \
    libncurses5-dev \
    libncursesw5-dev \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    python-is-python3 \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    libexpat1-dev \
    libgmp-dev \
    libmpfr-dev \
    libmpc-dev \
    libisl-dev \
    ninja-build \
    cmake \
    device-tree-compiler \
    curl \
    libusb-1.0-0 \
    libusb-1.0-0-dev

# Set up user to match typical host UID (optional but helpful for permissions)
RUN useradd -m -s /bin/bash esp32
WORKDIR /app

# The toolchain will be mounted at /app/toolchain
# The sources will be mounted at /app/sources
# Build outputs will be at /app/build-output

ENV PATH="/app/toolchain/xtensa-esp32s3-linux-uclibcfdpic/bin:${PATH}"
ENV XTENSA_GNU_CONFIG="/app/sources/xtensa-dynconfig/esp32s3.so"

USER esp32
CMD ["/bin/bash"]
