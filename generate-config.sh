#!/bin/bash

# 🔥 GPUForge Configuration Generator - Forge Your Perfect AI Infrastructure!
# Transform your AI dreams into optimized, production-ready Terraform configurations

set -e

echo "🔥 GPUForge Configuration Generator"
echo "===================================="
echo "⚡ Welcome to GPUForge! Let's forge your perfect AI infrastructure together."
echo "🧠 This intelligent generator analyzes your needs and creates optimized configurations"
echo "💡 that maximize performance while minimizing costs. Let's get started!"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration directory
CONFIG_DIR="generated-configs"
TEMPLATES_DIR="templates"

echo -e "${BLUE}🚀 GPUForge Configuration Generator${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$TEMPLATES_DIR"

# Function to display GPU options with cost analysis
show_gpu_options() {
    echo -e "${YELLOW}Available GPU Options:${NC}"
    echo
    echo -e "${GREEN}💰 Budget-Friendly (Development/Testing):${NC}"
    echo "  1) gpu-rtx4000x1-20gb    - 20GB VRAM  - ~$1.50/hour  - Good for: Small models, development"
    echo
    echo -e "${GREEN}⚡ Balanced Performance:${NC}"
    echo "  2) gpu-rtx6000ada-48gb   - 48GB VRAM  - ~$2.50/hour  - Good for: Medium models, production"
    echo "  3) gpu-a40x1-48gb        - 48GB VRAM  - ~$2.75/hour  - Good for: Training, inference"
    echo
    echo -e "${GREEN}🚀 High Performance:${NC}"
    echo "  4) gpu-h100x1-80gb       - 80GB VRAM  - ~$4.00/hour  - Good for: Large models, heavy workloads"
    echo "  5) gpu-h100x8-640gb      - 640GB VRAM - ~$32.00/hour - Good for: Massive models, multi-GPU"
    echo
}

# Function to get user requirements
get_requirements() {
    echo -e "${YELLOW}What's your primary use case?${NC}"
    echo "1) AI Development & Testing"
    echo "2) Model Training"
    echo "3) Production Inference Server"
    echo "4) MCP Tool Integration"
    echo "5) Research & Experimentation"
    echo
    read -p "Select use case (1-5): " use_case

    echo
    echo -e "${YELLOW}What's your budget preference?${NC}"
    echo "1) Budget-conscious (<$50/day)"
    echo "2) Balanced ($50-100/day)"
    echo "3) Performance-focused ($100-200/day)"
    echo "4) No budget constraints"
    echo
    read -p "Select budget (1-4): " budget

    echo
    show_gpu_options
    read -p "Select GPU option (1-5): " gpu_choice

    echo
    echo -e "${YELLOW}Additional features:${NC}"
    read -p "Enable Ollama? (y/n) [y]: " enable_ollama
    enable_ollama=${enable_ollama:-y}
    
    read -p "Enable LocalAI? (y/n) [y]: " enable_localai
    enable_localai=${enable_localai:-y}
    
    read -p "Enable volume protection? (y/n) [y]: " enable_protection
    enable_protection=${enable_protection:-y}
    
    read -p "Enable floating IP? (y/n) [n]: " enable_floating_ip
    enable_floating_ip=${enable_floating_ip:-n}

    echo
    read -p "Configuration name: " config_name
    config_name=${config_name:-"gpu-droplet-$(date +%Y%m%d)"}
}

# Function to generate configuration
generate_config() {
    local config_file="$CONFIG_DIR/${config_name}.tf"
    local vars_file="$CONFIG_DIR/${config_name}.tfvars"
    
    # Map GPU choices to actual sizes
    case $gpu_choice in
        1) gpu_size="gpu-rtx4000x1-20gb" ;;
        2) gpu_size="gpu-rtx6000ada-48gb" ;;
        3) gpu_size="gpu-a40x1-48gb" ;;
        4) gpu_size="gpu-h100x1-80gb" ;;
        5) gpu_size="gpu-h100x8-640gb" ;;
        *) gpu_size="gpu-rtx4000x1-20gb" ;;
    esac

    # Generate main configuration
    cat > "$config_file" << EOF
# Generated GPU Droplet Configuration
# Use case: $(get_use_case_name)
# Generated: $(date)

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
  # token is set via DIGITALOCEAN_TOKEN environment variable
}

# GPU Droplet Module
module "gpu_droplet" {
  source = "./modules/gpu_droplet"
  
  # Basic Configuration
  name     = var.droplet_name
  region   = var.region
  gpu_size = var.gpu_size
  
  # SSH Configuration (auto-import from DO account)
  auto_import_ssh_keys = true
  ssh_private_key_path = var.ssh_private_key_path
  
  # AI Services
  install_ollama   = var.enable_ollama
  install_localai  = var.enable_localai
  
  # Storage and Protection
  volume_size_gb    = var.volume_size_gb
  protect_volume    = var.enable_volume_protection
  
  # Network
  enable_floating_ip = var.enable_floating_ip
  enable_monitoring  = true
  
  # Project Assignment
  project_name = "Terraform Landing Project"
}

# Outputs
output "droplet_info" {
  description = "Essential droplet information"
  value = {
    ip_address    = module.gpu_droplet.droplet_ipv4
    floating_ip   = module.gpu_droplet.floating_ip
    ssh_command   = module.gpu_droplet.ssh_connection_info != null ? module.gpu_droplet.ssh_connection_info.ssh_command : null
    gpu_specs     = module.gpu_droplet.gpu_efficiency_analysis.performance_metrics
  }
}

output "cost_analysis" {
  description = "Cost breakdown and efficiency analysis"
  value = {
    hourly_cost   = module.gpu_droplet.cost_tracking.total_hourly_cost
    daily_cost    = module.gpu_droplet.cost_tracking.total_daily_cost
    monthly_cost  = module.gpu_droplet.cost_tracking.total_monthly_cost
    efficiency    = module.gpu_droplet.gpu_efficiency_analysis.efficiency_rankings
  }
}

output "model_recommendations" {
  description = "Ollama model recommendations for your GPU"
  value = {
    quick_start = module.gpu_droplet.ollama_quick_start
    mcp_models  = module.gpu_droplet.mcp_tool_model_recommendations
  }
}

output "management_commands" {
  description = "Commands for managing your droplet and models"
  value = {
    ssh_connection = module.gpu_droplet.ssh_connection_info
    ollama_management = module.gpu_droplet.ollama_management_commands
    volume_management = module.gpu_droplet.volume_management_commands
  }
}
EOF

    # Generate variables file
    cat > "$vars_file" << EOF
# Generated Variables for GPU Droplet Configuration
# Use case: $(get_use_case_name)
# Generated: $(date)

# Basic Configuration
droplet_name = "$config_name"
region       = "nyc2"  # Change as needed
gpu_size     = "$gpu_size"

# SSH Configuration
ssh_private_key_path = "~/.ssh/id_rsa"  # Update path as needed

# AI Services
enable_ollama  = $([ "$enable_ollama" = "y" ] && echo "true" || echo "false")
enable_localai = $([ "$enable_localai" = "y" ] && echo "true" || echo "false")

# Storage Configuration
volume_size_gb = $(get_volume_size)
enable_volume_protection = $([ "$enable_protection" = "y" ] && echo "true" || echo "false")

# Network Configuration
enable_floating_ip = $([ "$enable_floating_ip" = "y" ] && echo "true" || echo "false")
EOF

    # Generate variables.tf for the configuration
    cat > "$CONFIG_DIR/variables.tf" << 'EOF'
variable "droplet_name" {
  description = "Name for the GPU droplet"
  type        = string
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc2"
}

variable "gpu_size" {
  description = "GPU droplet size"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "enable_ollama" {
  description = "Enable Ollama installation"
  type        = bool
  default     = true
}

variable "enable_localai" {
  description = "Enable LocalAI installation"
  type        = bool
  default     = true
}

variable "volume_size_gb" {
  description = "Volume size in GB"
  type        = number
  default     = 100
}

variable "enable_volume_protection" {
  description = "Enable volume lifecycle protection"
  type        = bool
  default     = true
}

variable "enable_floating_ip" {
  description = "Enable floating IP"
  type        = bool
  default     = false
}
EOF

    echo -e "${GREEN}✅ Configuration generated successfully!${NC}"
    echo
    echo -e "${YELLOW}Files created:${NC}"
    echo "  📄 $config_file"
    echo "  📄 $vars_file"
    echo "  📄 $CONFIG_DIR/variables.tf"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Review and customize the generated configuration"
    echo "  2. 🔑 Set your DigitalOcean token: export DIGITALOCEAN_TOKEN=your_token"
    echo "  3. 🏗️ Initialize and forge: terraform init && terraform apply"
    echo "  4. 🚀 Connect via SSH using the provided connection command"
    echo "  5. 🤖 Start building AI magic with your optimized model recommendations!"
    echo
    echo "🎉 Welcome to GPUForge - Your AI Infrastructure is Forged and Ready!"
    echo "🔥 Ready to transform your AI dreams into reality? Run 'terraform apply' to forge your infrastructure!"
    echo "  • Volume protection and snapshot options"
}

# Helper functions
get_use_case_name() {
    case $use_case in
        1) echo "AI Development & Testing" ;;
        2) echo "Model Training" ;;
        3) echo "Production Inference Server" ;;
        4) echo "MCP Tool Integration" ;;
        5) echo "Research & Experimentation" ;;
        *) echo "General Purpose" ;;
    esac
}

get_volume_size() {
    case $gpu_choice in
        1) echo "50"  ;;  # Small GPU, smaller volume
        2|3) echo "100" ;;  # Medium GPU, standard volume
        4) echo "200" ;;  # Large GPU, larger volume
        5) echo "500" ;;  # Massive GPU, massive volume
        *) echo "100" ;;
    esac
}

# Main execution
main() {
    get_requirements
    generate_config
    
    echo -e "${GREEN}🎉 Ready to deploy your optimized GPU droplet!${NC}"
}

# Run main function
main
