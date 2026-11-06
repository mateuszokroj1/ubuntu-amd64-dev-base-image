# Ubuntu AMD64 Dev Base Image

Development image with C/C++ tools, Git LFS, and vcpkg. Build instructions are
available in the [Dockerfile](./Dockerfile).

## Operating system and architecture

- **Base image:** `ubuntu:latest`. This is a moving tag; the specific Ubuntu
  release depends on what the tag points to when the image is pulled.
- **Architecture:** the image is intended for `linux/amd64` (x86-64), as
  indicated by the directory name. The Dockerfile does not enforce a platform;
  without `--platform`, Docker selects the architecture appropriate for the
  build environment.
- **Working directory:** `/home`.

To build the image for amd64:

```sh
docker build --platform linux/amd64 -t ubuntu-amd64-dev-base-image .
```

## Technologies and versions

| Technology / packages | Version |
|---|---|
| Ubuntu | `latest`; the specific release is not pinned |
| Git LFS | `3.8.1` |
| Go (used only to build Git LFS) | `1.27.3` (`golang:1.27.3-bookworm`) |
| `golang.org/x/net` (dependency used to build Git LFS) | `v0.62.0` |
| `golang.org/x/crypto` (dependency used to build Git LFS) | `v0.58.1-0.20261009181718-2f1f834330b2` |
| vcpkg | Revision from the default branch of Microsoft's repository, fetched at build time; not pinned |
| `build-essential`, `gcc` | APT versions available at build time |
| `clang`, `clang-format`, `clang-tidy`, `clang-tools`, `clangd`, `python3-clang` | APT versions available at build time |
| `libc++-dev`, `libc++abi-dev`, `libclang-dev`, `liblldb-dev` | APT versions available at build time |
| `lld`, `lldb`, `llvm`, `llvm-dev`, `llvm-runtime` | APT versions available at build time |
| `ca-certificates`, `curl`, `git`, `tar`, `zip`, `unzip` | APT versions available at build time |

APT package versions are not pinned in the Dockerfile. They are fetched from
the current Ubuntu repositories (`apt update` and `apt full-upgrade`) and may
therefore change between builds. To check the operating system, architecture,
and exact package versions in a specific image, run:

```sh
cat /etc/os-release
dpkg --print-architecture
dpkg-query -W -f='${binary:Package}\t${Version}\n' \
  build-essential gcc clang clang-format clang-tidy clang-tools clangd \
  libc++-dev libc++abi-dev libclang-dev liblldb-dev lld lldb llvm llvm-dev \
  llvm-runtime python3-clang ca-certificates curl git tar zip unzip
git lfs version
vcpkg version
```
