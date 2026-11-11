# Ubuntu Dev Base Image

Development image with C/C++ tools, Python, Git LFS, and vcpkg. Build instructions are
available in the [Dockerfile](./Dockerfile).

## Operating system and architecture

- **Base image:** `ubuntu:26.04` (Ubuntu 26.04.1 LTS), pinned to digest
  `sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c`
  (multi-platform index for amd64 and arm64).
- **APT packages:** directly installed packages are pinned to specific
  versions. Their transitive dependencies are resolved from the Ubuntu 26.04
  archive at build time.
- **Architecture:** intended for `linux/amd64` (x86-64) and `linux/arm64` (ARM 64). The Dockerfile does not
  enforce a platform; without `--platform`, Docker selects the build host's
  architecture.
- **Working directory:** `/home`.

To build the image for amd64:

```sh
docker build --platform linux/amd64 -t mateuszokroj1/ubuntu-dev-base-image:ubuntu-26.04 .
```

## Technologies and versions

| Technology / packages | Version |
|---|---|
| Ubuntu | `26.04.1 LTS` (`26.04`) |
| Git LFS | `3.8.1`, commit `a662a6dbfedf706cfa9fc7a5b7bcc7ba2e2c8a65` |
| Go (used only to build Git LFS) | `1.27.3` (`golang:1.27.3-bookworm`, multi-platform index digest `sha256:dc0963f32053e4bc451d24d87e3892d42d01021b61f093e98eb95c0352bb84b0`) |
| `golang.org/x/net` (dependency used to build Git LFS) | `v0.62.0` |
| `golang.org/x/crypto` (dependency used to build Git LFS) | `v0.58.1-0.20261009181718-2f1f834330b2` |
| `github.com/klauspost/compress` (dependency used to build Git LFS) | `v1.20.2` |
| vcpkg source | Commit `9eec002df1cd109f8f104cd966a763daf9751489` (release `2026.10.16`) |
| vcpkg tool | `2026-09-26-51bf87ca6e9bf3e622d84ff323bd202ab1ca0c0b` |
| `build-essential` | `12.12ubuntu2.26.04.2` |
| GCC and G++ | GCC 15, package `15.2.0-16ubuntu1`; default metapackages `4:15.2.0-5ubuntu1` |
| LLVM, Clang, libc++, LLDB, LLD and Python bindings | LLVM `21.1.8-6ubuntu1`; generic aliases `1:21.1.6-71` |
| `ca-certificates` | `20260816ubuntu0.26.04.2` |
| `curl` | `8.18.0-1ubuntu2.8` |
| `git` | `2.53.0-1ubuntu1.1` |
| `tar` | `1.35+dfsg-4ubuntu0.4` |
| `zip` | `3.0-15ubuntu3` |
| `unzip` | `6.0-29ubuntu1` |

Directly installed APT packages are pinned in the Dockerfile. Transitive APT
dependencies are resolved from the current Ubuntu 26.04 repositories at build
time. To intentionally update patch levels, update the package versions and
base image digest together.

To check the operating system, architecture, and installed versions in a built
image:

```sh
cat /etc/os-release
dpkg --print-architecture
dpkg-query -W -f='${binary:Package}\t${Version}\n' \
  build-essential gcc g++ gcc-15 g++-15 clang-21 clang-format-21 \
  clang-tidy-21 clang-tools-21 clangd-21 libc++-21-dev libc++abi-21-dev \
  libclang-21-dev liblldb-21-dev lld-21 lldb-21 llvm-21 llvm-21-dev \
  llvm-21-runtime python3-clang-21 ca-certificates curl git tar zip unzip
git lfs version
vcpkg version
```
