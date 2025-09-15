#!/bin/sh
set -e

echo "Starting VM provisioning..."

if [ -f /tmp/corporate-ca.crt ]; then
    echo "Installing corporate CA certificate..."
    cp /tmp/corporate-ca.crt /usr/local/share/ca-certificates/corporate-ca.crt
    update-ca-certificates

    # Also add to curl's cert bundle
    cat /tmp/corporate-ca.crt >> /etc/ssl/certs/ca-certificates.crt
fi

export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

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
if [ -f /vagrant/config/tinyproxy.conf ]; then
    echo "Using custom TinyProxy configuration..."
    cp /vagrant/config/tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
fi

# Enable and start TinyProxy service
rc-update add tinyproxy default
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
