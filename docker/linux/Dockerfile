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
    ca-certificates gnupg
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

# Install GHCup, GHC and Cabal as the docker user
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
