# DigitalOcean GPU Droplet - Intelligent Configuration
# This configuration leverages the module's built-in intelligence for:
# - GPU cost efficiency analysis
# - VRAM-optimized model recommendations  
# - MCP tool-aware suggestions
# - SSH key auto-import
# - Volume protection and snapshots

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  # Set via: export DIGITALOCEAN_TOKEN=your_token_here
}

# Smart GPU Droplet with Built-in Intelligence
module "gpu_droplet" {
  source = "./modules/gpu_droplet"
  
  # === BASIC CONFIGURATION ===
  name     = var.droplet_name
  region   = var.region
  gpu_size = var.gpu_size
  
  # === SSH CONFIGURATION (Auto-Import from DO Account) ===
  auto_import_ssh_keys = true                    # Automatically use all your DO SSH keys
  ssh_key_names        = var.specific_ssh_keys   # Optional: specify particular keys
  ssh_private_key_path = var.ssh_private_key_path
  
  # === AI SERVICES ===
  install_ollama  = var.enable_ollama   # GPU-optimized Ollama with model recommendations
  install_localai = var.enable_localai  # OpenAI-compatible API endpoint
  
  # === INTELLIGENT STORAGE ===
  volume_size_gb = var.volume_size_gb    # Mounted at /mnt/ai-models for both services
  protect_volume = var.protect_volume    # Lifecycle protection against accidental deletion
  
  # === NETWORK & MONITORING ===
  enable_floating_ip = var.enable_floating_ip
  enable_monitoring  = true
  enable_backups     = var.enable_backups
  
  # === PROJECT ORGANIZATION ===
  project_name = var.project_name
}
