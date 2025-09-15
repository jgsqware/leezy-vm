#!/bin/bash
# Simple script to start Leezy VM with Lima via Devbox

echo "======================================"
echo "  Starting Leezy VM with Lima"
echo "======================================"
echo ""

# Load environment variables from .env if it exists
if [ -f .env ]; then
    echo "Loading configuration from .env..."
    set -a
    source .env
    set +a
else
    echo "⚠️  No .env file found. Creating from template..."
    cp .env.example .env
    echo "Please edit .env and add your TAILSCALE_AUTH_KEY"
    echo ""
fi

# Check if we're in a Devbox environment or if Lima is available
if ! command -v limactl &> /dev/null; then
    echo "❌ Lima is not available in this environment."
    echo ""
    echo "Use Devbox to manage Lima:"
    echo "  devbox shell -c devbox-lima.json"
    echo "  devbox run start"
    echo ""
    echo "Or if you want to install Lima system-wide:"
    echo "  brew install lima"
    exit 1
fi

# Check if VM already exists
if limactl list 2>/dev/null | grep -q "leezy-vm"; then
    echo "VM 'leezy-vm' already exists."
    read -p "Do you want to restart it? (y/n): " restart
    if [[ "$restart" == "y" ]]; then
        echo "Stopping existing VM..."
        limactl stop leezy-vm
        echo "Starting VM..."
        limactl start leezy-vm
    else
        echo "Connecting to existing VM..."
    fi
else
    echo "Creating and starting new VM..."
    limactl start --name=leezy-vm lima-leezy-vm.yaml
fi

echo ""
echo "======================================"
echo "✅ Leezy VM is running!"
echo "======================================"
echo ""
echo "Services:"
echo "  - Connect to VM: limactl shell leezy-vm"
echo "  - TinyProxy: http://localhost:8888"
echo ""
echo "Useful commands:"
echo "  - Check status: limactl list leezy-vm"
echo "  - Stop VM: limactl stop leezy-vm"
echo "  - Delete VM: limactl delete leezy-vm"
echo ""

# Check Tailscale status
echo "Checking Tailscale status..."
limactl shell leezy-vm sudo tailscale status 2>/dev/null || echo "Tailscale not yet authenticated"

echo ""
echo "======================================"