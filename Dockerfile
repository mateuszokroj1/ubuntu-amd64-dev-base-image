FROM mateuszokroj1/ubuntu-dev-base:ubuntu-26.04

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
    && powershell_version=7.7.0 \
    && case "$(dpkg --print-architecture)" in \
        amd64) powershell_arch=x64; powershell_sha256=c89d9c682d2c403dfe726f3df948e359675235a5bd6fab535776de69729ca0cb ;; \
        arm64) powershell_arch=arm64; powershell_sha256=e59c89776eaa59790d44b3edd14277435225ab08b6e7603763101b89de83d935 ;; \
        *) echo "Unsupported architecture for PowerShell" >&2; exit 1 ;; \
    esac \
    && mkdir -p /opt/microsoft/powershell/7 \
    && curl -fsSLo /tmp/powershell.tar.gz "https://github.com/PowerShell/PowerShell/releases/download/v${powershell_version}/powershell-${powershell_version}-linux-${powershell_arch}.tar.gz" \
    && echo "${powershell_sha256}  /tmp/powershell.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
    && rm /tmp/powershell.tar.gz \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh \
    && rm -rf /var/lib/apt/lists/*