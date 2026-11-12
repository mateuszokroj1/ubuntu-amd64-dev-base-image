FROM mateuszokroj1/ubuntu-dev-base:latest@sha256:e3936219db09bb1e0dc37df9c633fd146ef1f80577f09afd7bba8a887e7f91f0

# Start path is user dir
WORKDIR /home

# Install Git and configure the patched Git LFS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git \
    && git lfs version \
    && git lfs install --system \
    && rm -rf /var/lib/apt/lists/*

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
        default-jdk python3-full python3-dev python3-pip python3-venv \
        docker-ce-cli dotnet-sdk-10.0 tar zip unzip cargo \
    && apt-get remove -y nodejs \
    && apt-get autoremove -y \
    && case "$(dpkg --print-architecture)" in \
        amd64) node_arch=x64; node_sha256=9a6bc82f9b491279147219f6a18add1e18424dce90d41d2a5fcd69d4924ba3aa ;; \
        arm64) node_arch=arm64; node_sha256=0f3550d58d45e5d3cf7103d9e3f69937f09fe82fb5dd474c66a5d816fa58c9ee ;; \
        *) echo "Unsupported architecture for Node.js" >&2; exit 1 ;; \
    esac \
    && curl -fsSLo /tmp/node.tar.xz "https://nodejs.org/dist/v22.22.1/node-v22.22.1-linux-${node_arch}.tar.xz" \
    && echo "${node_sha256}  /tmp/node.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx /tmp/node.tar.xz \
    && node --version \
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