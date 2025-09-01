FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装基础依赖和 Playwright 系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    python3 \
    python3-pip \
    rsync \
    # Playwright 系统依赖
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libatspi2.0-0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libxcb1 \
    libxkbcommon0 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# 安装 Node.js 和 npm
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@latest

# 安装 Docker CLI (用于远程 Docker daemon 连接)
RUN wget -q https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz \
    && tar xzf docker-24.0.7.tgz \
    && mv docker/docker /usr/local/bin/ \
    && chmod +x /usr/local/bin/docker \
    && rm -rf docker docker-24.0.7.tgz

# 安装 Podman (remote client)
RUN wget -q https://github.com/containers/podman/releases/download/v4.7.0/podman-remote-static-linux_amd64.tar.gz \
    && tar -xzf podman-remote-static-linux_amd64.tar.gz -C /tmp \
    && mv /tmp/bin/podman-remote-static-linux_amd64 /usr/local/bin/podman \
    && chmod +x /usr/local/bin/podman \
    && rm -rf podman-remote-static-linux_amd64.tar.gz /tmp/bin

# 安装 kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# 安装 kind
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/kind

# 安装 Helm
RUN curl -Lo helm.tar.gz https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz \
    && tar -zxf helm.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf helm.tar.gz linux-amd64

# 设置工作目录
WORKDIR /workspace

# 复制依赖文件（分开复制以优化缓存）
COPY package*.json ./
COPY uv.lock pyproject.toml ./

# 安装 Python 依赖
RUN uv sync --frozen

# 安装 Node.js 依赖
RUN npm install

# 安装 Playwright browsers
RUN . .venv/bin/activate && playwright install-deps chromium

# 安装 playwright for node_modules（如果需要）
RUN if [ -d "node_modules/@lockon0927/playwright-mcp-with-chunk" ]; then \
        cd node_modules/@lockon0927/playwright-mcp-with-chunk && \
        npx playwright install chromium; \
    fi

# 安装 uv tools（合并为一个 RUN 命令减少层数）
RUN uv tool install office-powerpoint-mcp-server@2.0.6 \
    && uv tool install office-word-mcp-server@1.1.9 \
    && uv tool install git+https://github.com/lockon-n/wandb-mcp-server@83f6d7fe2ad2e6b6278aef4a792f35dd765fd315 \
    && uv tool install git+https://github.com/lockon-n/cli-mcp-server@da1dcb5166597c9fbf90ede5fb1f0cd22a71a3b7 \
    && uv tool install pdf-tools-mcp@0.1.4 \
    && uv tool install git+https://github.com/jkawamoto/mcp-youtube-transcript@28081729905a48bef533d864efbd867a2bfd14cd \
    && uv tool install mcp-google-sheets@0.4.1 \
    && uv tool install google-cloud-mcp@1.0.0 \
    && uv tool install emails-mcp@0.1.12 \
    && uv tool install git+https://github.com/lockon-n/mcp-snowflake-server@75c03ca0b3cee2da831e2bc1b3b7a150e4c2999a \
    && uv tool install git+https://github.com/lockon-n/mcp-scholarly@82a6ca268ae0d2e10664be396e1a0ea7aba23229

# 创建 local_servers 目录
RUN mkdir -p local_servers

# 克隆和安装 Git-based servers
WORKDIR /workspace/local_servers

# Yahoo Finance MCP
RUN git clone https://github.com/lockon-n/yahoo-finance-mcp \
    && cd yahoo-finance-mcp \
    && git checkout 27445a684dd2c65a6664620c5d057f66c42ea81f \
    && uv sync

# YouTube MCP Server
RUN git clone https://github.com/lockon-n/youtube-mcp-server \
    && cd youtube-mcp-server \
    && git checkout b202e00e9014bf74b9f5188b623cad16f13c01c4 \
    && npm install \
    && npm run build

# Arxiv LaTeX MCP
RUN git clone https://github.com/takashiishida/arxiv-latex-mcp.git \
    && cd arxiv-latex-mcp \
    && git checkout f8bd3b3b6d3d066fe29ba356023a0b3e8215da43 \
    && uv sync

# Google Forms MCP
RUN git clone https://github.com/matteoantoci/google-forms-mcp.git \
    && cd google-forms-mcp \
    && git checkout 96f7fa1ff02b8130105ddc6d98796f3b49c1c574 \
    && npm install \
    && npm run build \
    && npm audit fix --force || true

# 返回工作目录
WORKDIR /workspace

# 创建 local_binary 目录
RUN mkdir -p local_binary

# 健康检查（可选）
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD uv --version && node --version || exit 1

# 设置默认命令
CMD ["/bin/bash"]