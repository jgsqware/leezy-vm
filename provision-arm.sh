#!/bin/bash
set -e

echo "Starting VM provisioning (ARM/Ubuntu)..."

# Update package repository
apt-get update

# Install essential packages
apt-get install -y \
    openssh-server \
    curl \
    wget \
    sudo \
    iptables \
    ca-certificates \
    gnupg \
    lsb-release

# Configure SSH
echo "Configuring SSH..."
systemctl enable ssh
systemctl start ssh || true

# Allow password authentication for vagrant user
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh || true

# Install Tailscale
echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# Enable and start Tailscale service
systemctl enable tailscaled
systemctl start tailscaled || true

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
apt-get install -y tinyproxy

# Configure TinyProxy
cat > /etc/tinyproxy/tinyproxy.conf << 'EOF'
User tinyproxy
Group tinyproxy
Port 8888
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
LogLevel Info
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0

# Allow connections from any IP (adjust for security)
Allow 0.0.0.0/0

# Connection settings
ConnectPort 443
ConnectPort 563
ConnectPort 80
EOF

# Enable and start TinyProxy service
systemctl enable tinyproxy
systemctl restart tinyproxy || true

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