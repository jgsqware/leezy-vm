#!/bin/bash
# Start Leezy VM with Lima managed by Devbox

# Check if we have gum available for enhanced UI
if ! command -v gum &> /dev/null; then
    USE_PLAIN=true
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

# Main script starts here
show_header "Starting Leezy VM with Lima (Devbox)"

# Check if Devbox is installed
if ! command -v devbox &> /dev/null; then
    show_error "Devbox is not installed."
    echo ""
    show_info "Install Devbox:"
    echo "  curl -fsSL https://get.jetify.com/devbox | bash"
    echo ""
    exit 1
fi

# Create .env from template if it doesn't exist
if [ ! -f .env ]; then
    show_warning "No .env file found. Creating from template..."
    cp .env.example .env
    show_success "Created .env file."
    show_warning "Please edit .env and add your TAILSCALE_AUTH_KEY"
    echo ""
fi

if [[ "$USE_PLAIN" == "true" ]]; then
    echo "Starting Lima environment with Devbox..."
else
    gum style --foreground 117 --bold "Starting Lima environment with Devbox..."
fi

echo ""

# Enter Devbox environment and start the VM
if [[ "$USE_PLAIN" == "true" ]]; then
    devbox shell -c devbox-lima.json -- devbox run start
else
    gum spin --spinner dot --title "Initializing Devbox environment..." -- \
        devbox shell -c devbox-lima.json -- devbox run start
fi

echo ""

if [[ "$USE_PLAIN" == "true" ]]; then
    echo "======================================"
    echo "Lima VM management commands:"
    echo ""
    echo "Enter Lima environment:"
    echo "  devbox shell -c devbox-lima.json"
    echo ""
    echo "Within Lima environment:"
    echo "  devbox run start      # Start VM"
    echo "  devbox run connect    # Connect to VM"  
    echo "  devbox run stop       # Stop VM"
    echo "  devbox run status     # Check status"
    echo "  devbox run destroy    # Delete VM"
    echo ""
    echo "Direct Lima commands:"
    echo "  limactl list leezy-vm"
    echo "  limactl shell leezy-vm"
    echo "  limactl stop leezy-vm"
    echo "======================================"
else
    gum style \
        --foreground 117 \
        --border-foreground 117 \
        --border rounded \
        --padding "1 2" \
        --margin "1 0" \
        "Lima VM Management Commands"
    
    echo ""
    gum style --foreground 46 --bold "Enter Lima environment:"
    gum style --foreground 183 "  devbox shell -c devbox-lima.json"
    echo ""
    
    gum style --foreground 46 --bold "Within Lima environment:"
    gum style --foreground 183 "  devbox run start      # Start VM"
    gum style --foreground 183 "  devbox run connect    # Connect to VM"  
    gum style --foreground 183 "  devbox run stop       # Stop VM"
    gum style --foreground 183 "  devbox run status     # Check status"
    gum style --foreground 183 "  devbox run destroy    # Delete VM"
    echo ""
    
    gum style --foreground 46 --bold "Direct Lima commands:"
    gum style --foreground 183 "  limactl list leezy-vm"
    gum style --foreground 183 "  limactl shell leezy-vm"
    gum style --foreground 183 "  limactl stop leezy-vm"
fi