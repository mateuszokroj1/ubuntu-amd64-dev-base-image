FROM golang:1.27.3-bookworm@sha256:dc0963f32053e4bc451d24d87e3892d42d01021b61f093e98eb95c0352bb84b0 AS git-lfs-builder

RUN git init /src/git-lfs \
    && git -C /src/git-lfs fetch --depth 1 https://github.com/git-lfs/git-lfs.git refs/tags/v3.8.1:refs/tags/v3.8.1 \
    && test "$(git -C /src/git-lfs rev-parse 'v3.8.1^{tag}')" = 36e2915281bedab8aa4f0c8ef69fc183d7c4d0a5 \
    && git -C /src/git-lfs checkout --detach v3.8.1

WORKDIR /src/git-lfs

# Git LFS v3.8.1 bundles vulnerable versions of these modules.
RUN go get golang.org/x/net@v0.62.0 golang.org/x/crypto@v0.58.1-0.20261009181718-2f1f834330b2 github.com/klauspost/compress@v1.20.2 \
    && CGO_ENABLED=0 go build -trimpath -o /git-lfs . \
    && /git-lfs version \
    && test "$(go list -m -f '{{.Version}}' golang.org/x/net)" = v0.62.0 \
    && test "$(go list -m -f '{{.Version}}' golang.org/x/crypto)" = v0.58.1-0.20261009181718-2f1f834330b2 \
    && test "$(go list -m -f '{{.Version}}' github.com/klauspost/compress)" = v1.20.2

FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c

COPY --from=git-lfs-builder /git-lfs /usr/local/bin/git-lfs
COPY --from=git-lfs-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

WORKDIR /home

# Pin directly installed packages to Ubuntu 26.04-compatible versions.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential=12.12ubuntu2.26.04.2 \
        gcc=4:15.2.0-5ubuntu1 \
        gcc-15=15.2.0-16ubuntu1 \
        g++=4:15.2.0-5ubuntu1 \
        g++-15=15.2.0-16ubuntu1 \
        clang=1:21.1.6-71 \
        clang-21=1:21.1.8-6ubuntu1 \
        clang-format=1:21.1.6-71 \
        clang-format-21=1:21.1.8-6ubuntu1 \
        clang-tidy=1:21.1.6-71 \
        clang-tidy-21=1:21.1.8-6ubuntu1 \
        clang-tools=1:21.1.6-71 \
        clang-tools-21=1:21.1.8-6ubuntu1 \
        clangd=1:21.1.6-71 \
        clangd-21=1:21.1.8-6ubuntu1 \
        libc++-dev=1:21.1.6-71 \
        libc++-21-dev=1:21.1.8-6ubuntu1 \
        libc++abi-dev=1:21.1.6-71 \
        libc++abi-21-dev=1:21.1.8-6ubuntu1 \
        libclang-dev=1:21.1.6-71 \
        libclang-21-dev=1:21.1.8-6ubuntu1 \
        liblldb-dev=1:21.1.6-71 \
        liblldb-21-dev=1:21.1.8-6ubuntu1 \
        lld=1:21.1.6-71 \
        lld-21=1:21.1.8-6ubuntu1 \
        lldb=1:21.1.6-71 \
        lldb-21=1:21.1.8-6ubuntu1 \
        llvm=1:21.1.6-71 \
        llvm-21=1:21.1.8-6ubuntu1 \
        llvm-dev=1:21.1.6-71 \
        llvm-21-dev=1:21.1.8-6ubuntu1 \
        llvm-runtime=1:21.1.6-71 \
        llvm-21-runtime=1:21.1.8-6ubuntu1 \
        python3-clang=1:21.1.6-71 \
        python3-clang-21=1:21.1.8-6ubuntu1 \
        ca-certificates=20260816ubuntu0.26.04.2 \
        curl=8.18.0-1ubuntu2.8 \
        git=1:2.53.0-1ubuntu1.1 \
        tar=1.35+dfsg-4ubuntu0.4 \
        zip=3.0-15ubuntu3 \
        unzip=6.0-29ubuntu1 \
    && git lfs version \
    && git lfs install --system \
    && rm -rf /var/lib/apt/lists/*

RUN git init /home/vcpkg \
    && git -C /home/vcpkg fetch --depth 1 https://github.com/microsoft/vcpkg.git 9eec002df1cd109f8f104cd966a763daf9751489 \
    && git -C /home/vcpkg checkout --detach FETCH_HEAD \
    && ./vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_ROOT="/home/vcpkg"
ENV PATH="${VCPKG_ROOT}:${PATH}"
