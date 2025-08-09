# Use the official dockcross windows static x64 image as base
FROM dockcross/windows-static-x64:latest

# Install essential build tools inside the container (Debian-based)
RUN apt-get update && apt-get install -y \
    vim-common \
    xxd \
    build-essential \
    patch \
    unzip \
    cmake \
    python3 python3-pip python3-packaging \
    && rm -rf /var/lib/apt/lists/*

# Build Boost and zlib using MXE
RUN cd /usr/src/mxe && make boost zlib sdl2 sdl2_image libslirp

# Optionally clean up to reduce image size (MXE build cache can be big)
RUN rm -rf /usr/src/mxe/builds/* /tmp/*
