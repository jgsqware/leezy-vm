#!/bin/bash
# Setup script for macOS with Gum UI enhancements

# Check if we have gum available, if not install it for enhanced UI
if ! command -v gum &> /dev/null; then
    # Try to install gum via Homebrew if available
    if command -v brew &> /dev/null; then
        echo "Installing Gum for enhanced UI..."
        brew install gum
    else
        # Fallback to plain text interface
        USE_PLAIN=true
    fi
fi

# Helper functions for styled output
show_header() {
    if [[ "$USE_PLAIN" == "true" ]]; then
        echo "======================================"
        echo "  $1"
        echo "======================================"
    else
        gum style \
            --foreground 212 \
            --border-foreground 212 \
            --border double \
            --align center \
            --width 50 \
            --margin "1 2" \
            --padding "2 4" \
            "$1"
    fi
    echo ""
}

show_success() {
    if [[ "$USE_PLAIN" == "true" ]]; then
        echo "✅ $1"
    else
        gum style --foreground 46 "✅ $1"
    fi
}

show_warning() {
    if [[ "$USE_PLAIN" == "true" ]]; then
        echo "⚠️  $1"
    else
        gum style --foreground 214 "⚠️  $1"
    fi
}

show_error() {
    if [[ "$USE_PLAIN" == "true" ]]; then
        echo "❌ $1"
    else
        gum style --foreground 196 "❌ $1"
    fi
}

show_info() {
    if [[ "$USE_PLAIN" == "true" ]]; then
        echo "$1"
    else
        gum style --foreground 117 "$1"
    fi
}

# Main setup starts here
show_header "Leezy VM - macOS Setup"

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    show_success "Apple Silicon (ARM64) detected"
else
    show_success "Intel (x86_64) detected"
fi

# Detect OS
if [[ "$OSTYPE" != "darwin"* ]]; then
    show_error "This script is for macOS only."
    echo "   Your OS: $OSTYPE"
    exit 1
fi

# Create .env from template if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    show_success "Created .env file from template"
    echo ""
    show_warning "Please edit .env and add your TAILSCALE_AUTH_KEY"
    echo "   Get your key from: https://login.tailscale.com/admin/settings/keys"
    echo ""
fi

# Prompt user for preferred method
if [[ "$USE_PLAIN" == "true" ]]; then
    echo "Select your preferred virtualization method:"
    echo ""
    echo "  1) Lima (Recommended - Lightweight, native macOS support)"
    echo "  2) Vagrant with virtualization provider"
    echo ""
    read -p "Enter your choice (1 or 2): " choice
else
    choice=$(gum choose \
        --header "Select your preferred virtualization method:" \
        --header.foreground 117 \
        "Lima (Recommended - Lightweight, native macOS support)" \
        "Vagrant with virtualization provider")

    if [[ "$choice" == "Lima"* ]]; then
        choice="1"
    else
        choice="2"
    fi
fi

if [[ "$choice" == "1" ]]; then
    # Lima setup
    echo ""
    show_info "Setting up with Lima via Devbox..."
    echo ""

    # Check if Devbox is installed
    if ! command -v devbox &> /dev/null; then
        show_info "Installing Devbox..."

        if [[ "$USE_PLAIN" == "true" ]]; then
            curl -fsSL https://get.jetify.com/devbox | bash
        else
            gum spin --spinner dot --title "Installing Devbox..." -- \
                bash -c "curl -fsSL https://get.jetify.com/devbox | bash"
        fi

        # Reload shell to ensure devbox is available
        export PATH="$HOME/.local/bin:$PATH"

        if ! command -v devbox &> /dev/null; then
            show_error "Failed to install Devbox. Please restart your terminal and try again."
            exit 1
        fi
    else
        show_success "Devbox is already installed"
    fi

    show_success "Lima will be installed and managed within Devbox environment"
    echo ""

    show_success "Using devbox-lima.json as devbox.json"
    cp devbox-lima.json devbox.json

    if [[ "$USE_PLAIN" == "true" ]]; then
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
    else
        gum style \
            --foreground 46 \
            --border-foreground 46 \
            --border rounded \
            --align center \
            --width 50 \
            --margin "1 2" \
            --padding "2 4" \
            "✅ Lima Setup Complete!"

        echo ""
        gum style --foreground 117 --bold "Next steps:"
        echo ""
        gum style --foreground 183 "Start the VM:"
        gum style --foreground 183 "  devbox shell -c devbox-lima.json"
        gum style --foreground 183 "  devbox run start"
        echo ""
        gum style --foreground 183 "Connect to VM:"
        gum style --foreground 183 "  devbox run connect"
    fi

elif [[ "$choice" == "2" ]]; then
    # Vagrant setup
    echo ""
    show_info "Setting up with Vagrant..."
    echo ""

    # Use ARM-optimized Vagrantfile for Apple Silicon
    if [[ "$ARCH" == "arm64" ]]; then
        show_info "Using ARM-optimized Vagrantfile..."
        cp Vagrantfile.arm Vagrantfile
    fi

    # Check for virtualization providers
    show_info "Checking for virtualization providers..."
    echo ""

    PROVIDER=""

    # Check for VMware Fusion
    if command -v vmrun &> /dev/null; then
        show_success "VMware Fusion detected"
        PROVIDER="vmware_desktop"

        # Check for vagrant plugin
        if ! vagrant plugin list | grep -q vagrant-vmware-desktop; then
            show_info "Installing Vagrant VMware plugin..."
            if [[ "$USE_PLAIN" == "true" ]]; then
                vagrant plugin install vagrant-vmware-desktop
            else
                gum spin --spinner dot --title "Installing plugin..." -- \
                    vagrant plugin install vagrant-vmware-desktop
            fi
        fi
    elif command -v prlctl &> /dev/null; then
        show_success "Parallels Desktop detected"
        PROVIDER="parallels"

        # Check for vagrant plugin
        if ! vagrant plugin list | grep -q vagrant-parallels; then
            show_info "Installing Vagrant Parallels plugin..."
            if [[ "$USE_PLAIN" == "true" ]]; then
                vagrant plugin install vagrant-parallels
            else
                gum spin --spinner dot --title "Installing plugin..." -- \
                    vagrant plugin install vagrant-parallels
            fi
        fi
    elif command -v docker &> /dev/null; then
        show_success "Docker detected"
        PROVIDER="docker"
    else
        show_error "No supported virtualization provider found!"
        echo ""
        show_info "Please install one of the following:"
        echo "  1. VMware Fusion (recommended): https://www.vmware.com/products/fusion.html"
        echo "  2. Parallels Desktop: https://www.parallels.com/"
        echo "  3. Docker Desktop: https://www.docker.com/products/docker-desktop/"
        echo ""
        exit 1
    fi

    echo ""
    if [[ "$USE_PLAIN" == "true" ]]; then
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
        gum style \
            --foreground 46 \
            --border-foreground 46 \
            --border rounded \
            --align center \
            --width 50 \
            --margin "1 2" \
            --padding "2 4" \
            "✅ Vagrant Setup Complete!"

        echo ""
        gum style --foreground 117 --bold "Next steps:"
        echo ""
        gum style --foreground 183 "Start the VM:"
        gum style --foreground 183 "  VAGRANT_DEFAULT_PROVIDER=$PROVIDER vagrant up"
        echo ""
        gum style --foreground 183 "Or set as default:"
        gum style --foreground 183 "  export VAGRANT_DEFAULT_PROVIDER=$PROVIDER"
    fi
else
    show_error "Invalid choice. Please run the script again and select 1 or 2."
    exit 1
fi
