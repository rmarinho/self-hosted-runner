FROM ubuntu:24.04

ARG RUNNER_VERSION="2.334.0"
ARG DEBIAN_FRONTEND=noninteractive

# Update and upgrade the system
RUN apt update -y && apt upgrade -y

# Add a user named docker
RUN useradd -m docker

# Install necessary packages (including Docker CLI for Docker-in-Docker via socket mount)
RUN apt install -y --no-install-recommends \
    curl build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip jq \
    libgmp-dev libncurses-dev libnuma-dev zlib1g-dev pkg-config \
    ca-certificates gnupg unzip
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update -qq \
    && apt-get install -y -qq docker-ce-cli docker-buildx-plugin
RUN apt-get -yqq install ssh locales \
    && locale-gen en_US.UTF-8
# Set up the actions runner (auto-detect architecture)
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then RUNNER_ARCH="arm64"; else RUNNER_ARCH="x64"; fi \
    && curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz

# Change ownership to docker user, grant sudo for Docker socket fixup, install deps
RUN chown -R docker /home/docker && /home/docker/actions-runner/bin/installdependencies.sh
RUN apt-get install -y -qq sudo && echo "docker ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set UTF-8 locale
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ─────────────────────────────────────────────
# .NET 10 SDK
# ─────────────────────────────────────────────
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="${DOTNET_ROOT}:${DOTNET_ROOT}/tools:${PATH}"
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin \
        --channel 10.0 --install-dir "$DOTNET_ROOT" \
    && dotnet --info

# ─────────────────────────────────────────────
# Java 17 (OpenJDK)
# ─────────────────────────────────────────────
RUN apt-get install -y -qq openjdk-17-jdk-headless
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-$(dpkg --print-architecture)

# ─────────────────────────────────────────────
# Android SDK + .NET MAUI Android workload
# ─────────────────────────────────────────────
ENV ANDROID_HOME=/usr/local/android-sdk
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null 2>&1 \
    && sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.1" \
    && chmod -R a+rw ${ANDROID_HOME}
RUN dotnet workload install maui-android

# ─────────────────────────────────────────────
# Haskell (GHCup, GHC, Cabal)
# ─────────────────────────────────────────────
USER docker
ENV PATH="/home/docker/.ghcup/bin:/home/docker/.cabal/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=9.8.4 \
    BOOTSTRAP_HASKELL_CABAL_VERSION=latest \
    BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 \
    sh
RUN ghcup install ghc 9.10.3 && cabal update
USER root

# Copy the start script and make it executable
COPY --chmod=+x start.sh /start.sh

# Switch to docker user
USER docker

# Define the entrypoint
ENTRYPOINT ["/start.sh"]
