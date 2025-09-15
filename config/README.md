# Configuration Files

This directory contains configuration files for the services running in Leezy VM.

## Files

### tinyproxy.conf
Configuration for TinyProxy HTTP/HTTPS proxy server.

**Key settings:**
- Port: 8888
- Access: Allows connections from any IP (0.0.0.0/0)
- Max Clients: 100
- Timeout: 600 seconds

**To customize:**
1. Edit `tinyproxy.conf` before starting the VM
2. Adjust access control rules for production use
3. Add additional ConnectPort entries for your applications
4. Configure upstream proxy if needed

**Security Note:** 
The default configuration allows connections from any IP. For production use, restrict the `Allow` directive to specific IP ranges.

### tailscale-acl.json
Example Tailscale ACL (Access Control List) configuration.

**Features:**
- Tag-based device organization
- Service-specific access rules
- SSH access configuration
- Funnel support for TinyProxy

**To use:**
1. Customize the ACL for your needs
2. Upload to https://login.tailscale.com/admin/acls
3. Tag your Leezy VM with appropriate tags

### services.env
Environment variables for service configuration.

**Includes:**
- TinyProxy settings
- Tailscale options
- SSH configuration
- System resource allocation

**Note:** These are example values. The actual configuration is controlled by:
- Lima: `lima-leezy-vm.yaml`
- Vagrant: `Vagrantfile` and provisioning scripts

## Configuration Loading

### Lima
- Config files are mounted at `/tmp/leezy-config/`
- TinyProxy config is automatically copied during provisioning

### Vagrant
- Config files are available at `/vagrant/config/`
- Provisioning scripts check for and use custom configs

## Adding New Configuration Files

When adding new service configurations:
1. Place the config file in this directory
2. Update the Lima YAML or provisioning scripts to copy the file
3. Document the configuration here
4. Consider adding environment variables to `services.env`