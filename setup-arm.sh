#!/bin/bash
# Setup script for macOS (optimized for Apple Silicon)

echo "======================================"
echo "  Leezy VM - macOS Setup"
echo "======================================"
echo ""

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "✅ Apple Silicon (ARM64) detected"
else
    echo "✅ Intel (x86_64) detected"
fi

# Detect OS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  This script is for macOS only."
    echo "   Your OS: $OSTYPE"
    exit 1
fi

# Create .env from template if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created .env file from template"
    echo ""
    echo "⚠️  Please edit .env and add your TAILSCALE_AUTH_KEY"
    echo "   Get your key from: https://login.tailscale.com/admin/settings/keys"
    echo ""
fi

# Prompt user for preferred method
echo "Select your preferred virtualization method:"
echo ""
echo "  1) Lima (Recommended - Lightweight, native macOS support)"
echo "  2) Vagrant with virtualization provider"
echo ""
read -p "Enter your choice (1 or 2): " choice

if [[ "$choice" == "1" ]]; then
    # Lima setup
    echo ""
    echo "Setting up with Lima via Devbox..."
    echo ""
    
    # Check if Devbox is installed
    if ! command -v devbox &> /dev/null; then
        echo "Installing Devbox..."
        curl -fsSL https://get.jetify.com/devbox | bash
        
        # Reload shell to ensure devbox is available
        export PATH="$HOME/.local/bin:$PATH"
        
        if ! command -v devbox &> /dev/null; then
            echo "❌ Failed to install Devbox. Please restart your terminal and try again."
            exit 1
        fi
    else
        echo "✅ Devbox is already installed"
    fi
    
    echo "✅ Lima will be installed and managed within Devbox environment"
    echo ""
    echo "======================================"
    echo "Lima setup complete!"
    echo ""
    echo "To start the VM with Lima:"
    echo "  devbox shell -c devbox-lima.json"
    echo "  devbox run start"
    echo ""
    echo "To connect to the VM:"
    echo "  devbox shell -c devbox-lima.json"
    echo "  devbox run connect"
    echo "======================================"
    
elif [[ "$choice" == "2" ]]; then
    # Vagrant setup
    echo ""
    echo "Setting up with Vagrant..."
    echo ""
    
    # Use ARM-optimized Vagrantfile for Apple Silicon
    if [[ "$ARCH" == "arm64" ]]; then
        echo "Using ARM-optimized Vagrantfile..."
        cp Vagrantfile.arm Vagrantfile
    fi
    
    # Check for virtualization providers
    echo "Checking for virtualization providers..."
    echo ""
    
    PROVIDER=""
    
    # Check for VMware Fusion
if command -v vmrun &> /dev/null; then
    echo "✅ VMware Fusion detected"
    PROVIDER="vmware_desktop"

    # Check for vagrant plugin
    if ! vagrant plugin list | grep -q vagrant-vmware-desktop; then
        echo "Installing Vagrant VMware plugin..."
        vagrant plugin install vagrant-vmware-desktop
    fi
elif command -v prlctl &> /dev/null; then
    echo "✅ Parallels Desktop detected"
    PROVIDER="parallels"

    # Check for vagrant plugin
    if ! vagrant plugin list | grep -q vagrant-parallels; then
        echo "Installing Vagrant Parallels plugin..."
        vagrant plugin install vagrant-parallels
    fi
elif command -v docker &> /dev/null; then
        echo "✅ Docker detected"
        PROVIDER="docker"
    else
        echo "⚠️  No supported virtualization provider found!"
        echo ""
        echo "Please install one of the following:"
        echo "  1. VMware Fusion (recommended): https://www.vmware.com/products/fusion.html"
        echo "  2. Parallels Desktop: https://www.parallels.com/"
        echo "  3. Docker Desktop: https://www.docker.com/products/docker-desktop/"
        echo ""
        exit 1
    fi
    
    echo ""
    echo "======================================"
    echo "Vagrant setup complete!"
    echo ""
    echo "To start the VM, run:"
    echo "  VAGRANT_DEFAULT_PROVIDER=$PROVIDER vagrant up"
    echo ""
    echo "Or add to your shell profile:"
    echo "  export VAGRANT_DEFAULT_PROVIDER=$PROVIDER"
    echo "======================================"
else
    echo "Invalid choice. Please run the script again and select 1 or 2."
    exit 1
fi
