FROM golang:1.27.3-bookworm AS git-lfs-builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v3.8.1 https://github.com/git-lfs/git-lfs.git /src/git-lfs

WORKDIR /src/git-lfs

# Git LFS v3.8.1 bundles vulnerable versions of these modules.
RUN go get golang.org/x/net@v0.62.0 golang.org/x/crypto@v0.58.1-0.20261009181718-2f1f834330b2 \
    && CGO_ENABLED=0 go build -trimpath -o /git-lfs . \
    && /git-lfs version \
    && test "$(go list -m -f '{{.Version}}' golang.org/x/net)" = v0.62.0 \
    && test "$(go list -m -f '{{.Version}}' golang.org/x/crypto)" = v0.58.1-0.20261009181718-2f1f834330b2

FROM ubuntu:latest

COPY --from=git-lfs-builder /git-lfs /usr/local/bin/git-lfs

# Start path is user dir
WORKDIR /home

# Install updates
RUN apt update
RUN apt full-upgrade -y

# Install basic dev-libs
RUN apt install build-essential gcc clang-format clang-tidy clang-tools clang clangd libc++-dev libc++abi-dev libclang-dev liblldb-dev lld lldb llvm-dev llvm-runtime llvm python3-clang -y

# Install Git and configure the patched Git LFS build
RUN apt install -y ca-certificates curl git \
    && git lfs version \
    && git lfs install --system

# Install vcpkg system dependencies
RUN apt install -y curl tar zip unzip

# Clone repo of vcpkg
RUN git clone https://github.com/microsoft/vcpkg

RUN ./vcpkg/bootstrap-vcpkg.sh 

ENV VCPKG_ROOT="/home/vcpkg"
ENV PATH="${VCPKG_ROOT}:${PATH}"
