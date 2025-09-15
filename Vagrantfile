# -*- mode: ruby -*-
# vi: set ft=ruby :
# Vagrantfile for Apple Silicon (ARM) Macs

# Load environment variables from .env file if it exists
if File.exist?('.env')
  File.foreach('.env') do |line|
    next if line.strip.empty? || line.strip.start_with?('#')
    key, value = line.strip.split('=', 2)
    ENV[key] = value if key && value
  end
end

Vagrant.configure("2") do |config|
  # Use Ubuntu ARM64 box for Apple Silicon compatibility
  config.vm.box = "generic/alpine318"

  # VM configuration
  config.vm.hostname = ENV['TAILSCALE_HOSTNAME'] || "leezy-vm"

  # Forward TinyProxy port
  config.vm.network "forwarded_port", guest: 8888, host: 8888

  # VMware Fusion provider (recommended for Apple Silicon)
  config.vm.provider "vmware_desktop" do |vmware|
    vmware.vmx["displayname"] = "leezy-vm"
    vmware.vmx["memsize"] = "512"
    vmware.vmx["numvcpus"] = "1"
  end

  # Parallels provider
  config.vm.provider "parallels" do |prl|
    prl.name = "leezy-vm"
    prl.memory = 512
    prl.cpus = 1
  end

  # Docker provider (lightweight alternative)
  config.vm.provider "docker" do |docker|
    docker.image = "alpine:latest"
    docker.has_ssh = true
    docker.remains_running = true
  end

  # Load configuration from environment (from .env file or system env)
  tailscale_auth_key = ENV['TAILSCALE_AUTH_KEY'] || ""
  tailscale_hostname = ENV['TAILSCALE_HOSTNAME'] || "leezy-vm"
  tailscale_accept_routes = ENV['TAILSCALE_ACCEPT_ROUTES'] || "true"


  config.vm.provision "file", source: "./corporate-ca.crt", destination: "/tmp/corporate-ca.crt"

  # Provisioning - adapted for Ubuntu/Debian systems
  config.vm.provision "shell", path: "provision.sh", env: {
    "TAILSCALE_AUTH_KEY" => tailscale_auth_key,
    "TAILSCALE_HOSTNAME" => tailscale_hostname,
    "TAILSCALE_ACCEPT_ROUTES" => tailscale_accept_routes
  }
end
