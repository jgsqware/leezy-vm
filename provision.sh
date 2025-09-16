#!/bin/sh
set -e

echo "Starting VM provisioning..."

if [ -f /tmp/corporate-chain.pem ]; then
    echo "Installing corporate CA certificate..."
    cp /tmp/corporate-chain.pem /usr/local/share/ca-certificates/corporate-chain.crt
    update-ca-certificates
fi

# Update package repository
apk update

# Install essential packages
apk add --no-cache \
    openssh \
    openssh-server \
    curl \
    wget \
    bash \
    sudo \
    iptables \
    ip6tables \
    helix \
    dos2unix \
    ca-certificates

# Configure SSH
echo "Configuring SSH..."
rc-update add sshd default
rc-service sshd start || true

# Allow password authentication for vagrant user
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
rc-service sshd restart || true

# Install Tailscale
echo "Installing Tailscale..."
apk add --no-cache tailscale

# Enable and start Tailscale service
rc-update add tailscale default
rc-service tailscale start || true


# Auto-authenticate Tailscale if auth key is provided
if [ ! -z "$TAILSCALE_AUTH_KEY" ]; then
    echo "Authenticating Tailscale with provided auth key..."
    sleep 2  # Give tailscale service time to fully start

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

    tailscale down || true
    # Execute the command
    eval $TS_CMD || {
        echo "Warning: Tailscale authentication failed. You may need to authenticate manually."
    }
    echo "Tailscale authentication attempted. Checking status..."
    tailscale status || true
fi

# Install TinyProxy
echo "Installing TinyProxy..."
apk add --no-cache tinyproxy

# Configure TinyProxy
# Check if custom config exists in Vagrant shared folder
if [ -f /tmp/tinyproxy.conf ]; then
    echo "Using custom TinyProxy configuration..."
    cp /tmp/tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
    dos2unix /etc/tinyproxy/tinyproxy.conf
fi

mkdir -p /var/run/tinyproxy /var/log/tinyproxy
# Enable and start TinyProxy service
rc-update add tinyproxy default
sed -i 's|=/run|=/var/run/tinyproxy/|' /etc/init.d/tinyproxy
rc-service tinyproxy start || true

# Create a startup script for Tailscale authentication
cat > /home/vagrant/tailscale-setup.sh << 'EOF'
#!/bin/bash
echo "==================================="
echo "Tailscale Setup"
echo "==================================="
echo ""
echo "To connect this VM to your Tailscale network:"
echo "1. Run: sudo tailscale up"
echo "2. Follow the authentication link provided"
echo "3. Once authenticated, you can access this VM via Tailscale IP"
echo ""
echo "To check Tailscale status: sudo tailscale status"
echo ""
EOF

chmod +x /home/vagrant/tailscale-setup.sh
chown vagrant:vagrant /home/vagrant/tailscale-setup.sh

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
echo ""
if [ -z "$TAILSCALE_AUTH_KEY" ]; then
    echo "To complete Tailscale setup, SSH into the VM and run:"
    echo "  ./tailscale-setup.sh"
    echo ""
fi
echo "TinyProxy is accessible on:"
echo "  - Guest: 0.0.0.0:8888"
echo "  - Host: localhost:8888"
echo "===================================="
