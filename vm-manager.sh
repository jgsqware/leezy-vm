#!/bin/bash
# Gum-enhanced VM manager script for Leezy VM

# Check if we have gum available for enhanced UI
if ! command -v gum &> /dev/null; then
    echo "❌ Gum is not available. Please install it or run within a Devbox environment."
    echo ""
    echo "Install Gum:"
    echo "  brew install gum"
    echo ""
    echo "Or use Devbox:"
    echo "  devbox shell -c devbox-lima.json"
    exit 1
fi

# Helper functions
show_header() {
    gum style \
        --foreground 212 \
        --border-foreground 212 \
        --border double \
        --align center \
        --width 60 \
        --margin "1 2" \
        --padding "2 4" \
        "🚀 Leezy VM Manager" \
        "Interactive VM Management"
    echo ""
}

show_success() {
    gum style --foreground 46 "✅ $1"
}

show_error() {
    gum style --foreground 196 "❌ $1"
}

show_info() {
    gum style --foreground 117 "$1"
}

# Detect available VM systems
detect_vm_systems() {
    local systems=()
    
    # Check for Lima (via Devbox)
    if [ -f "devbox-lima.json" ]; then
        systems+=("Lima (via Devbox)")
    fi
    
    # Check for Vagrant
    if command -v vagrant &> /dev/null; then
        if [ -f "Vagrantfile" ]; then
            systems+=("Vagrant")
        fi
    fi
    
    # Check for Docker
    if command -v docker &> /dev/null; then
        systems+=("Docker")
    fi
    
    echo "${systems[@]}"
}

# Lima operations
lima_operations() {
    local action=$(gum choose \
        --header "Lima VM Operations:" \
        --header.foreground 117 \
        "Start VM" \
        "Connect to VM" \
        "Stop VM" \
        "Check Status" \
        "Destroy VM" \
        "View Logs" \
        "Tailscale Status" \
        "Back to Main Menu")
    
    case "$action" in
        "Start VM")
            gum style --foreground 117 --bold "Starting Lima VM..."
            devbox shell -c devbox-lima.json -- devbox run start
            ;;
        "Connect to VM")
            gum style --foreground 117 --bold "Connecting to Lima VM..."
            devbox shell -c devbox-lima.json -- devbox run connect
            ;;
        "Stop VM")
            gum style --foreground 214 --bold "Stopping Lima VM..."
            devbox shell -c devbox-lima.json -- devbox run stop
            ;;
        "Check Status")
            gum style --foreground 117 --bold "Lima VM Status:"
            devbox shell -c devbox-lima.json -- devbox run status
            ;;
        "Destroy VM")
            if gum confirm "Are you sure you want to destroy the Lima VM?"; then
                gum style --foreground 196 --bold "Destroying Lima VM..."
                devbox shell -c devbox-lima.json -- devbox run destroy
            fi
            ;;
        "View Logs")
            gum style --foreground 117 --bold "Lima VM Logs:"
            devbox shell -c devbox-lima.json -- devbox run logs
            ;;
        "Tailscale Status")
            gum style --foreground 117 --bold "Tailscale Status:"
            devbox shell -c devbox-lima.json -- devbox run tailscale-status
            ;;
        "Back to Main Menu")
            return
            ;;
    esac
    
    echo ""
    gum style --foreground 183 "Press Enter to continue..."
    read
}

# Vagrant operations
vagrant_operations() {
    local action=$(gum choose \
        --header "Vagrant VM Operations:" \
        --header.foreground 117 \
        "Start VM" \
        "Connect to VM" \
        "Stop VM" \
        "Check Status" \
        "Provision VM" \
        "Destroy VM" \
        "Back to Main Menu")
    
    case "$action" in
        "Start VM")
            gum style --foreground 117 --bold "Starting Vagrant VM..."
            gum spin --spinner dot --title "Starting VM..." -- vagrant up
            show_success "VM started successfully!"
            ;;
        "Connect to VM")
            gum style --foreground 117 --bold "Connecting to Vagrant VM..."
            vagrant ssh
            ;;
        "Stop VM")
            gum style --foreground 214 --bold "Stopping Vagrant VM..."
            gum spin --spinner dot --title "Stopping VM..." -- vagrant halt
            show_success "VM stopped"
            ;;
        "Check Status")
            gum style --foreground 117 --bold "Vagrant VM Status:"
            vagrant status
            ;;
        "Provision VM")
            gum style --foreground 117 --bold "Re-provisioning Vagrant VM..."
            gum spin --spinner dot --title "Provisioning..." -- vagrant provision
            show_success "Provisioning complete"
            ;;
        "Destroy VM")
            if gum confirm "Are you sure you want to destroy the Vagrant VM?"; then
                gum style --foreground 196 --bold "Destroying Vagrant VM..."
                gum spin --spinner dot --title "Destroying VM..." -- vagrant destroy -f
                show_success "VM destroyed"
            fi
            ;;
        "Back to Main Menu")
            return
            ;;
    esac
    
    echo ""
    gum style --foreground 183 "Press Enter to continue..."
    read
}

# Environment setup
setup_environment() {
    local action=$(gum choose \
        --header "Environment Setup:" \
        --header.foreground 117 \
        "Create .env file" \
        "Edit .env file" \
        "View current .env" \
        "Check Tailscale key" \
        "Back to Main Menu")
    
    case "$action" in
        "Create .env file")
            if [ -f .env ]; then
                if gum confirm ".env file already exists. Overwrite?"; then
                    cp .env.example .env
                    show_success "Created new .env file from template"
                fi
            else
                cp .env.example .env
                show_success "Created .env file from template"
            fi
            ;;
        "Edit .env file")
            if [ -f .env ]; then
                ${EDITOR:-nano} .env
            else
                show_error ".env file not found. Create it first."
            fi
            ;;
        "View current .env")
            if [ -f .env ]; then
                gum style --foreground 117 --bold "Current .env configuration:"
                echo ""
                # Show .env but mask sensitive values
                cat .env | sed 's/\(.*KEY.*=\).*/\1***masked***/'
            else
                show_error ".env file not found"
            fi
            ;;
        "Check Tailscale key")
            if [ -f .env ]; then
                source .env
                if [ ! -z "$TAILSCALE_AUTH_KEY" ]; then
                    show_success "Tailscale auth key is configured"
                    gum style --foreground 183 "Key: ${TAILSCALE_AUTH_KEY:0:12}...***masked***"
                else
                    show_error "Tailscale auth key not configured"
                fi
            else
                show_error ".env file not found"
            fi
            ;;
        "Back to Main Menu")
            return
            ;;
    esac
    
    echo ""
    gum style --foreground 183 "Press Enter to continue..."
    read
}

# Main menu
main_menu() {
    while true; do
        clear
        show_header
        
        # Detect available VM systems
        local systems=($(detect_vm_systems))
        
        if [ ${#systems[@]} -eq 0 ]; then
            show_error "No VM systems detected!"
            gum style --foreground 183 "Make sure you have either Lima (devbox-lima.json) or Vagrant installed."
            exit 1
        fi
        
        gum style --foreground 46 --bold "Available VM systems:"
        for system in "${systems[@]}"; do
            gum style --foreground 183 "  ✓ $system"
        done
        echo ""
        
        local choice=$(gum choose \
            --header "What would you like to do?" \
            --header.foreground 117 \
            "🚀 Lima Operations" \
            "📦 Vagrant Operations" \
            "⚙️  Environment Setup" \
            "📋 View VM Status" \
            "❌ Exit")
        
        case "$choice" in
            "🚀 Lima Operations")
                if [[ " ${systems[@]} " =~ " Lima (via Devbox) " ]]; then
                    lima_operations
                else
                    show_error "Lima not available. Install Devbox and devbox-lima.json"
                    echo ""
                    gum style --foreground 183 "Press Enter to continue..."
                    read
                fi
                ;;
            "📦 Vagrant Operations")
                if [[ " ${systems[@]} " =~ " Vagrant " ]]; then
                    vagrant_operations
                else
                    show_error "Vagrant not available. Install Vagrant and ensure Vagrantfile exists"
                    echo ""
                    gum style --foreground 183 "Press Enter to continue..."
                    read
                fi
                ;;
            "⚙️  Environment Setup")
                setup_environment
                ;;
            "📋 View VM Status")
                gum style --foreground 117 --bold "Current VM Status:"
                echo ""
                
                # Check Lima status
                if [[ " ${systems[@]} " =~ " Lima (via Devbox) " ]]; then
                    gum style --foreground 46 --bold "Lima VM:"
                    if command -v devbox &> /dev/null; then
                        devbox shell -c devbox-lima.json -- devbox run status 2>/dev/null || echo "  Not running"
                    fi
                fi
                
                # Check Vagrant status
                if [[ " ${systems[@]} " =~ " Vagrant " ]]; then
                    echo ""
                    gum style --foreground 46 --bold "Vagrant VM:"
                    vagrant status 2>/dev/null || echo "  Not available"
                fi
                
                echo ""
                gum style --foreground 183 "Press Enter to continue..."
                read
                ;;
            "❌ Exit")
                gum style --foreground 46 "👋 Goodbye!"
                exit 0
                ;;
        esac
    done
}

# Start the application
main_menu