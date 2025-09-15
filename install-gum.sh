#!/bin/bash
# Install Gum for enhanced UI across different platforms

echo "======================================"
echo "  Installing Gum for Enhanced UI"
echo "======================================"
echo ""

# Detect platform
case "$(uname -s)" in
    Darwin)
        echo "macOS detected"
        if command -v brew &> /dev/null; then
            echo "Installing Gum via Homebrew..."
            brew install gum
        else
            echo "❌ Homebrew not found. Please install Homebrew first:"
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
        ;;
    Linux)
        echo "Linux detected"
        
        # Try different package managers
        if command -v apt &> /dev/null; then
            echo "Installing Gum via apt..."
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install gum
        elif command -v yum &> /dev/null; then
            echo "Installing Gum via yum..."
            echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
            sudo yum install gum
        elif command -v pacman &> /dev/null; then
            echo "Installing Gum via pacman..."
            sudo pacman -S gum
        else
            echo "❌ No supported package manager found. Please install Gum manually:"
            echo "   https://github.com/charmbracelet/gum#installation"
            exit 1
        fi
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo "Windows detected"
        if command -v winget &> /dev/null; then
            echo "Installing Gum via winget..."
            winget install charmbracelet.gum
        elif command -v choco &> /dev/null; then
            echo "Installing Gum via Chocolatey..."
            choco install gum
        else
            echo "❌ No supported package manager found. Please install Gum manually:"
            echo "   https://github.com/charmbracelet/gum#installation"
            exit 1
        fi
        ;;
    *)
        echo "❌ Unsupported platform: $(uname -s)"
        echo "Please install Gum manually:"
        echo "   https://github.com/charmbracelet/gum#installation"
        exit 1
        ;;
esac

# Verify installation
if command -v gum &> /dev/null; then
    echo ""
    echo "✅ Gum installed successfully!"
    echo ""
    echo "You can now use enhanced scripts:"
    echo "  ./setup-macos.sh       # Enhanced macOS setup"
    echo "  ./vm-manager.sh        # Interactive VM manager"
    echo "  ./start-lima-devbox.sh # Enhanced Lima startup"
else
    echo ""
    echo "❌ Gum installation failed. Please check the error messages above."
    exit 1
fi