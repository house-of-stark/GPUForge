{{ ... }}

variable "bucket_policy" {
  description = "JSON policy for the bucket (optional)"

# === BASIC CONFIGURATION ===
variable "droplet_name" {
  description = "Name for your GPU droplet"
  type        = string
  default     = "ai-gpu-droplet"
}

variable "region" {
  description = "DigitalOcean region (module validates GPU availability)"
  type        = string
  default     = "nyc2"
}

variable "gpu_size" {
  description = "GPU droplet size (module provides cost/efficiency analysis)"
  type        = string
  default     = "gpu-rtx4000x1-20gb"  # Budget-friendly default
  
  # Module handles validation and provides recommendations
}

# === SSH CONFIGURATION (Auto-Import) ===
variable "specific_ssh_keys" {
  description = "Specific SSH key names to import (empty = all keys from DO account)"
  type        = list(string)
  default     = []  # Import all SSH keys from your DigitalOcean account
}

variable "ssh_private_key_path" {
  description = "Path to your private SSH key for connections"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# === AI SERVICES ===
variable "enable_ollama" {
  description = "Install Ollama with GPU-optimized model recommendations"
  type        = bool
  default     = true
}

variable "enable_localai" {
  description = "Install LocalAI with OpenAI-compatible API"
  type        = bool
  default     = true
}

# === INTELLIGENT STORAGE ===
variable "volume_size_gb" {
  description = "Volume size for AI model storage (module recommends based on GPU)"
  type        = number
  default     = 100  # Module provides size recommendations
}

variable "protect_volume" {
  description = "Enable volume lifecycle protection (prevents accidental deletion)"
  type        = bool
  default     = true  # Recommended for AI model storage
}

# === NETWORK & FEATURES ===
variable "enable_floating_ip" {
  description = "Enable floating IP for static external access"
  type        = bool
  default     = false
}

variable "enable_backups" {
  description = "Enable automatic droplet backups (20% additional cost)"
  type        = bool
  default     = false
}

# === PROJECT ORGANIZATION ===
variable "project_name" {
  description = "DigitalOcean project for resource organization"
  type        = string
  default     = "AI GPU Droplets"
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs to add to the droplet"
  type        = list(string)
  default     = []
}

variable "gpu_droplet_user_data" {
  description = "User data script for GPU droplet initialization"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable DigitalOcean monitoring for the droplet"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the droplet"
  type        = bool
  default     = true
}

variable "vpc_uuid" {
  description = "UUID of the VPC to place the droplet in (optional)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = list(string)
  default     = ["terraform", "gpu"]
}

variable "gpu_droplet_tags" {
  description = "Additional tags specific to the GPU droplet"
  type        = list(string)
  default     = ["gpu-compute"]
}

variable "volume_ids" {
  description = "List of volume IDs to attach to the droplet"
  type        = list(string)
  default     = []
}

variable "resize_disk" {
  description = "Whether to resize the disk when changing droplet size"
  type        = bool
  default     = true
}

variable "graceful_shutdown" {
  description = "Whether to attempt graceful shutdown before destroying"
  type        = bool
  default     = true
}

# Floating IP Variables
variable "create_floating_ip" {
  description = "Whether to create and assign a floating IP"
  type        = bool
  default     = false
}

# Firewall Variables
variable "create_firewall" {
  description = "Whether to create firewall rules for the droplet"
  type        = bool
  default     = true
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses/ranges allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Allow from anywhere (change for security)
}

variable "allow_web_traffic" {
  description = "Whether to allow HTTP/HTTPS traffic"
  type        = bool
  default     = false
}

variable "custom_inbound_rules" {
  description = "Custom inbound firewall rules"
  type = list(object({
    protocol         = string
    port_range       = string
    source_addresses = list(string)
  }))
  default = []
}

# Volume Variables
variable "create_volume" {
  description = "Whether to create an additional volume"
  type        = bool
  default     = false
}

variable "volume_size" {
  description = "Size of the additional volume in GB"
  type        = number
  default     = 100
  
  validation {
    condition     = var.volume_size >= 1 && var.volume_size <= 16384
    error_message = "Volume size must be between 1 and 16384 GB."
  }
}

variable "volume_filesystem" {
  description = "Initial filesystem type for the volume"
  type        = string
  default     = "ext4"
  
  validation {
    condition = contains([
      "ext4", "xfs"
    ], var.volume_filesystem)
    error_message = "Volume filesystem must be ext4 or xfs."
  }
}
