# syntax=docker/dockerfile:1

FROM ubuntu:25.04

# Install required packages
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    wget \
    bash \
    sudo \
    iptables \
    ca-certificates \
    tinyproxy \
    systemd \
    systemd-sysv \
    dos2unix \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Install Devbox
RUN curl -fsSL https://get.jetify.com/devbox | bash -s -- -f

# Build arguments for dynamic user creation
ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG GROUPNAME

# Create user with same UID/GID as local user to avoid permission issues
RUN if ! getent group ${USER_GID} > /dev/null 2>&1; then \
    groupadd -g ${USER_GID} ${GROUPNAME}; \
    fi && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USERNAME} && \
    usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory ownership
RUN mkdir -p /workspace && chown -R ${USERNAME}:${GROUPNAME} /workspace

# Embed provision script
RUN cat > /provision.sh << 'PROVISION_SCRIPT'
#!/bin/bash
set -e

echo "Starting container provisioning..."

if [ -f /tmp/corporate-chain.pem ]; then
echo "Installing corporate CA certificate..."
cp /tmp/corporate-chain.pem /usr/local/share/ca-certificates/corporate-chain.crt
update-ca-certificates
fi

# Configure SSH
echo "Configuring SSH..."
mkdir -p /var/run/sshd
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
service ssh start || true

# Start Tailscale
echo "Starting Tailscale..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sleep 2

# Auto-authenticate Tailscale if auth key is provided
if [ ! -z "$TAILSCALE_AUTH_KEY" ]; then
echo "Authenticating Tailscale with provided auth key..."

# Build tailscale up command with options
TS_CMD="tailscale up --authkey=\"$TAILSCALE_AUTH_KEY\""

# Add hostname if provided
if [ ! -z "$TAILSCALE_HOSTNAME" ]; then
TS_CMD="$TS_CMD --hostname=\"$TAILSCALE_HOSTNAME\""
fi

# Add accept-routes flag if enabled
if [ "$TAILSCALE_ACCEPT_ROUTES" = "true" ]; then
TS_CMD="$TS_CMD --accept-routes"
fi

if [ "$TAILSCALE_ACCEPT_DNS" = "false" ]; then
TS_CMD="$TS_CMD --accept-dns=$TAILSCALE_ACCEPT_DNS"
cat > /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 10.25.29.1
search tail98dd.ts.net local
EOF
else
TS_CMD="$TS_CMD --accept-dns=$TAILSCALE_ACCEPT_DNS"
fi

# Execute the command
eval $TS_CMD || {
echo "Warning: Tailscale authentication failed. You may need to authenticate manually."
}
echo "Tailscale authentication attempted. Checking status..."
tailscale status || true
fi

# Configure TinyProxy
if [ -f /tmp/tinyproxy.conf ]; then
echo "Using custom TinyProxy configuration..."
cp /tmp/tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
dos2unix /etc/tinyproxy/tinyproxy.conf
fi

# Start TinyProxy
echo "Starting TinyProxy..."
mkdir -p /var/run/tinyproxy /var/log/tinyproxy
tinyproxy -c /etc/tinyproxy/tinyproxy.conf

# # Initialize Devbox if devbox.json is present
# if [ -f /workspace/devbox.json ]; then
# echo "Initializing Devbox environment..."
# cd /workspace
# devbox install || true
# fi

# Display service status
echo ""
echo "==================================="
echo "Provisioning Complete!"
echo "==================================="
echo "Services installed:"
echo "  - SSH (port 22)"
if [ ! -z "$TAILSCALE_AUTH_KEY" ]; then
echo "  - Tailscale (authenticated automatically)"
else
echo "  - Tailscale (not authenticated yet)"
fi
echo "  - TinyProxy (port 8888)"
echo "  - Devbox (installed)"
echo "  - Jetify (installed)"
echo ""
echo "TinyProxy is accessible on:"
echo "  - Container: 0.0.0.0:8888"
echo "  - Host: localhost:8888"
echo "===================================="
PROVISION_SCRIPT

RUN chmod +x /provision.sh

# Expose TinyProxy port
EXPOSE 8888

# Switch to the created user
USER ${USERNAME}
WORKDIR /workspace

# Keep container running
CMD ["/bin/bash", "-c", "sudo /provision.sh && tail -f /dev/null"]
