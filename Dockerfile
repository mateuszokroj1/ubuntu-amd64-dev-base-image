FROM golang:1.27.3-bookworm AS git-lfs-builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v3.8.1 https://github.com/git-lfs/git-lfs.git /src/git-lfs

WORKDIR /src/git-lfs

# Git LFS v3.8.1 bundles vulnerable versions of these modules.
RUN go get golang.org/x/net@v0.62.0 golang.org/x/crypto@v0.58.1-0.20261009181718-2f1f834330b2 github.com/klauspost/compress@v1.20.2 \
    && CGO_ENABLED=0 go build -trimpath -o /git-lfs . \
    && /git-lfs version \
    && test "$(go list -m -f '{{.Version}}' golang.org/x/net)" = v0.62.0 \
    && test "$(go list -m -f '{{.Version}}' golang.org/x/crypto)" = v0.58.1-0.20261009181718-2f1f834330b2 \
    && test "$(go list -m -f '{{.Version}}' github.com/klauspost/compress)" = v1.20.2

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

# Install additional language SDKs and command-line tools
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && . /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME:-$VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list \
    && curl -fsSLo /tmp/packages-microsoft-prod.deb "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs default-jdk python3-full python3-dev python3-pip python3-venv \
        docker-ce-cli dotnet-sdk-10.0 tar zip unzip cargo \
    && case "$(dpkg --print-architecture)" in \
        amd64) powershell_arch=x64 ;; \
        arm64) powershell_arch=arm64 ;; \
        *) echo "Unsupported architecture for PowerShell" >&2; exit 1 ;; \
    esac \
    && powershell_version="$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | sed -nE 's/^[[:space:]]*"tag_name": "v([^"]+)".*/\1/p' | head -n 1)" \
    && test -n "$powershell_version" \
    && mkdir -p /opt/microsoft/powershell/7 \
    && curl -fsSL "https://github.com/PowerShell/PowerShell/releases/download/v${powershell_version}/powershell-${powershell_version}-linux-${powershell_arch}.tar.gz" \
        | tar -xz -C /opt/microsoft/powershell/7 \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh \
    && rm -rf /var/lib/apt/lists/*

# Clone repo of vcpkg
RUN git clone https://github.com/microsoft/vcpkg

RUN ./vcpkg/bootstrap-vcpkg.sh 

ENV VCPKG_ROOT="/home/vcpkg"
ENV PATH="${VCPKG_ROOT}:${PATH}"
