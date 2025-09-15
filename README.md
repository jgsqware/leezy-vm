# Leezy VM - Lightweight Vagrant Box

A simple and lightweight Vagrant box with Alpine Linux, SSH, Tailscale, and TinyProxy.

## Features

- **Alpine Linux 3.18** - Minimal footprint (~512MB RAM)
- **SSH** - Pre-configured for remote access
- **Tailscale** - Zero-config VPN for secure networking
- **TinyProxy** - Lightweight HTTP/HTTPS proxy server

## Requirements

### Platform-Specific Requirements

#### Windows
- PowerShell (Run as Administrator)
- VirtualBox will be installed automatically

#### macOS Intel (x86_64)
- [Devbox](https://www.jetify.com/devbox) or manual Vagrant + VirtualBox installation

#### macOS Apple Silicon (M1/M2/M3)
- [Devbox](https://www.jetify.com/devbox) for dependency management
- One of these virtualization providers:
  - [VMware Fusion](https://www.vmware.com/products/fusion.html) (free for personal use) - **Recommended**
  - [Parallels Desktop](https://www.parallels.com/) (commercial)
  - Docker Desktop (lightweight alternative)
  - QEMU/libvirt (open source)

#### Linux
- [Devbox](https://www.jetify.com/devbox) or manual Vagrant + VirtualBox/libvirt installation

## Quick Start

### Windows One-Liner Installation

#### Option 1: PowerShell (Recommended)
Open PowerShell as Administrator and run:

```powershell
irm https://raw.githubusercontent.com/jgsqware/leezy-vm/main/install-windows.ps1 | iex
```

Or with your Tailscale auth key:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/jgsqware/leezy-vm/main/install-windows.ps1))) -TailscaleAuthKey "tskey-auth-xxxxx"
```

#### Option 2: Download and Run Batch File
For users who prefer not to run PowerShell commands directly:

1. Download: https://raw.githubusercontent.com/jgsqware/leezy-vm/main/install.bat
2. Right-click `install.bat` and select "Run as administrator"

#### What it does:
- Installs Chocolatey package manager
- Installs Git, VirtualBox, and Vagrant
- Clones the repository to `~/leezy-vm`
- Creates `.env` file with your auth key (if provided)
- Starts the VM automatically

### macOS (Intel & Apple Silicon)

#### Option 1: Lima (Recommended for macOS)

**Quick Setup:**
```bash
./setup-arm.sh  # Choose option 1 for Lima
```

**Manual Lima Setup:**
1. Install Devbox (Lima will be managed within Devbox):
   ```bash
   curl -fsSL https://get.jetify.com/devbox | bash
   ```

2. Start VM with Devbox:
   ```bash
   devbox shell -c devbox-lima.json
   devbox run start
   ```

3. Alternative startup script:
   ```bash
   ./start-lima-devbox.sh
   ```

**Lima Benefits:**
- ✅ Native macOS support (Intel & Apple Silicon)
- ✅ No additional virtualization software needed
- ✅ Lightweight and fast
- ✅ Built-in file sharing
- ✅ Managed within Devbox (isolated environment)

#### Option 2: Vagrant with Virtualization Providers

**Quick Setup:**
```bash
./setup-arm.sh  # Choose option 2 for Vagrant
```

**Manual Setup Options:**

##### VMware Fusion (Recommended for Apple Silicon)
1. Install [VMware Fusion](https://www.vmware.com/products/fusion.html) (free for personal use)
2. Install Vagrant VMware provider:
   ```bash
   vagrant plugin install vagrant-vmware-desktop
   ```
3. Use the ARM-optimized Vagrantfile:
   ```bash
   cp Vagrantfile.arm Vagrantfile  # For Apple Silicon
   VAGRANT_DEFAULT_PROVIDER=vmware_desktop vagrant up
   ```

##### Parallels Desktop
1. Install [Parallels Desktop](https://www.parallels.com/)
2. Install Vagrant Parallels provider:
   ```bash
   vagrant plugin install vagrant-parallels
   ```
3. Start the VM:
   ```bash
   cp Vagrantfile.arm Vagrantfile  # For Apple Silicon
   VAGRANT_DEFAULT_PROVIDER=parallels vagrant up
   ```

##### VirtualBox (Intel Macs only)
```bash
devbox shell -c devbox-intel.json  # Uses VirtualBox
devbox run start
```

##### Docker (Lightweight alternative)
```bash
cp Vagrantfile.arm Vagrantfile
VAGRANT_DEFAULT_PROVIDER=docker vagrant up
```

### Using Devbox (Linux/Intel macOS)

1. Install Devbox and enter the shell:
   ```bash
   # Install devbox if you haven't already
   curl -fsSL https://get.jetify.com/devbox | bash
   
   # For Intel Macs with VirtualBox:
   devbox shell -c devbox-intel.json
   
   # For Linux or ARM Macs with QEMU/libvirt:
   devbox shell
   ```

2. The Devbox environment will:
   - Install Vagrant and virtualization tools
   - Create `.env` from template if it doesn't exist
   - Show available commands

3. Use Devbox scripts for VM management:
   ```bash
   devbox run setup     # Create .env from template
   devbox run start     # Start the VM
   devbox run connect   # SSH into the VM
   devbox run stop      # Stop the VM
   devbox run status    # Check VM status
   devbox run provision # Re-provision the VM
   devbox run clean     # Destroy the VM
   ```

### Manual Setup

#### 1. Setup Configuration

Copy the example environment file and add your Tailscale auth key:
```bash
cp .env.example .env
# Edit .env and add your Tailscale auth key
```

#### 2. Start the VM

```bash
vagrant up
```

The VM will automatically:
- Read configuration from `.env` file
- Authenticate with Tailscale using your auth key
- Configure all services

#### 3. Access the VM

```bash
vagrant ssh
```

## Service Configuration

### SSH
- Available on standard port 22
- Password authentication enabled for vagrant user
- Root login disabled for security

### Tailscale

#### Secure Configuration with .env File (Recommended)

1. Create your `.env` file from the template:
   ```bash
   cp .env.example .env
   ```

2. Add your configuration to `.env`:
   ```bash
   # Required: Your Tailscale auth key
   TAILSCALE_AUTH_KEY=tskey-auth-xxxxx
   
   # Optional: Custom hostname (default: leezy-vm)
   TAILSCALE_HOSTNAME=my-custom-vm
   
   # Optional: Accept advertised routes (default: true)
   TAILSCALE_ACCEPT_ROUTES=true
   ```

3. Get your auth key from: https://login.tailscale.com/admin/settings/keys
   - Recommended: Create a reusable auth key with appropriate tags

#### Alternative: Environment Variables
You can also pass the auth key directly (less secure):
```bash
TAILSCALE_AUTH_KEY="tskey-auth-xxxxx" vagrant up
```

#### Manual Authentication
If you didn't provide an auth key during provisioning:

1. SSH into the VM: `vagrant ssh`
2. Run the setup helper: `./tailscale-setup.sh`
3. Authenticate: `sudo tailscale up`
4. Follow the authentication link
5. Check status: `sudo tailscale status`

### TinyProxy
- Listening on port 8888
- Accessible from host at `localhost:8888`
- Configuration: `/etc/tinyproxy/tinyproxy.conf`

To use as proxy:
```bash
# HTTP proxy
export http_proxy=http://localhost:8888
export https_proxy=http://localhost:8888

# Or configure in your browser/application
```

## VM Management

### Lima (macOS)
```bash
# Start VM (recommended approach)
./start-lima-devbox.sh

# Or manually with Devbox
devbox shell -c devbox-lima.json
devbox run start

# Connect to VM (within Devbox environment)
devbox shell -c devbox-lima.json
devbox run connect

# Or use Lima directly (if available)
limactl shell leezy-vm

# Other commands (within Devbox environment)
devbox run status     # Check VM status
devbox run stop       # Stop VM  
devbox run destroy    # Delete VM
```

### Vagrant (All platforms)

#### Windows (PowerShell)
Navigate to `~/leezy-vm` (or your install path) and use:
```powershell
vagrant up          # Start VM
vagrant ssh         # Connect to VM
vagrant halt        # Stop VM
vagrant reload      # Restart VM
vagrant provision   # Re-provision VM
vagrant destroy     # Destroy VM
vagrant status      # Check status
```

#### Linux/macOS
```bash
# Using Devbox scripts
devbox run start     # Start VM
devbox run connect   # SSH into VM
devbox run stop      # Stop VM
devbox run status    # Check status
devbox run provision # Re-provision VM
devbox run clean     # Destroy VM

# Or using Vagrant directly
vagrant up          # Start VM
vagrant ssh         # Connect to VM
vagrant halt        # Stop VM
vagrant reload      # Restart VM
vagrant provision   # Re-provision VM
vagrant destroy     # Destroy VM
```

## Configuration

### Resource Allocation
Edit `Vagrantfile` to adjust:
- Memory: Default 512MB
- CPUs: Default 1

### Network
- Private network with DHCP
- Port forwarding: 8888 (TinyProxy)

## Troubleshooting

### Check service status
```bash
# Inside VM
sudo rc-service sshd status
sudo rc-service tailscale status
sudo rc-service tinyproxy status
```

### View logs
```bash
# TinyProxy logs
sudo tail -f /var/log/tinyproxy/tinyproxy.log

# System logs
sudo tail -f /var/log/messages
```

## Security Notes

- **Never commit `.env` file to version control** - it contains sensitive auth keys
- Use reusable Tailscale auth keys with appropriate ACL tags
- Change default passwords after initial setup
- Configure TinyProxy ACLs for production use
- Review SSH configuration for your security requirements
- Tailscale provides encrypted connections by default

## Files

### Lima Configuration
- `lima-leezy-vm.yaml` - Lima VM configuration for macOS
- `devbox-lima.json` - Devbox configuration for Lima management
- `start-lima.sh` - Lima startup script (checks for native Lima)
- `start-lima-devbox.sh` - Lima startup script via Devbox (recommended)

### Vagrant Configuration
- `Vagrantfile` - Main VM configuration (supports multiple providers)
- `Vagrantfile.arm` - ARM-optimized configuration for Apple Silicon Macs
- `provision.sh` - Provisioning script for Alpine Linux
- `provision-arm.sh` - Provisioning script for Ubuntu/Debian (ARM systems)
- `devbox.json` - Devbox configuration with Docker provider
- `devbox-intel.json` - Devbox configuration with VirtualBox for Intel Macs

### Platform Setup
- `setup-arm.sh` - macOS setup script (supports Lima and Vagrant)
- `install-windows.ps1` - Windows automated installation script
- `install.bat` - Windows batch file wrapper for easy execution

### Configuration
- `.env.example` - Template for environment variables (safe to commit)
- `.env` - Your actual configuration with secrets (gitignored)
- `.gitignore` - Ensures `.env` and Devbox files are never committed