# Required Variables
variable "enabled" {
  description = "Enable or disable the GPU droplet creation"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the GPU droplet"
  type        = string
}

variable "region" {
  description = "The region to create the GPU droplet in"
  type        = string
  
  validation {
    condition     = contains(["nyc1", "nyc2", "nyc3", "tor1", "atl1", "sfo3", "ams3", "sgp1", "lon1", "fra1", "blr1", "syd1"], var.region)
    error_message = "Invalid region. Must be one of: nyc1, nyc2, nyc3, tor1, atl1, sfo3, ams3, sgp1, lon1, fra1, blr1, syd1. Note: GPU droplets are only available in nyc2, tor1, and atl1."
  }
}

variable "gpu_size" {
  description = "The size of the GPU droplet"
  type        = string
  default     = "gpu-h100x1-80gb"
  
  validation {
    condition = contains([
      "gpu-rtx4000x1-20gb", "gpu-rtx6000ada-48gb", "gpu-a40x1-48gb",
      "gpu-h100x1-80gb", "gpu-h100x8-640gb", "gpu-a100x1-80gb", "gpu-a100x8-640gb"
    ], var.gpu_size)
    error_message = "Invalid GPU size. Must be one of: gpu-rtx4000x1-20gb, gpu-rtx6000ada-48gb, gpu-a40x1-48gb, gpu-h100x1-80gb, gpu-h100x8-640gb, gpu-a100x1-80gb, gpu-a100x8-640gb"
  }
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs to add to the droplet (leave empty to use auto_import_ssh_keys)"
  type        = list(string)
  default     = []
}

variable "auto_import_ssh_keys" {
  description = "Automatically import all SSH keys from your DigitalOcean account"
  type        = bool
  default     = true
}

variable "ssh_key_names" {
  description = "List of SSH key names to import from your DigitalOcean account (if empty, imports all keys)"
  type        = list(string)
  default     = []
}

# Optional Variables
variable "image" {
  description = "The image ID or slug to use for the droplet"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "tags" {
  description = "A list of tags to apply to the droplet"
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "User data to provide when launching the droplet"
  type        = string
  default     = ""
}

variable "vpc_uuid" {
  description = "The ID of the VPC where the droplet will be located"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable monitoring for the droplet"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable backups for the droplet"
  type        = bool
  default     = false
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the droplet"
  type        = bool
  default     = true
}

variable "volume_size_gb" {
  description = "Size of the volume to attach to the droplet in GB"
  type        = number
  default     = 0
}

variable "volume_filesystem" {
  description = "Filesystem type for the volume"
  type        = string
  default     = "ext4"
}

variable "protect_volume" {
  description = "Protect volume from accidental destruction (recommended for AI model storage)"
  type        = bool
  default     = true
}

variable "create_volume_snapshot_on_destroy" {
  description = "Create a snapshot of the volume before destroying it (requires doctl)"
  type        = bool
  default     = false
}

variable "volume_snapshot_name" {
  description = "Name for the volume snapshot (if not provided, will use volume name with timestamp)"
  type        = string
  default     = ""
}

variable "enable_floating_ip" {
  description = "Assign a floating IP to the droplet"
  type        = bool
  default     = false
}

variable "enable_firewall" {
  description = "Create a firewall for the droplet"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks to allow SSH access from"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "additional_inbound_rules" {
  description = "Additional inbound rules for the firewall"
  type = list(object({
    protocol         = string
    port_range       = string
    source_addresses = list(string)
  }))
  default = []
}

variable "use_timestamp" {
  description = "Append a timestamp to the droplet name for uniqueness"
  type        = bool
  default     = false
}

variable "enable_cost_tracking" {
  description = "Enable cost tracking for the GPU droplet"
  type        = bool
  default     = true
}

# LocalAI Configuration
variable "install_localai" {
  description = "Install LocalAI on the GPU droplet"
  type        = bool
  default     = false
}

variable "localai_models" {
  description = "List of model files to download for LocalAI (format: model_name=url)"
  type        = list(string)
  default     = [
    "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf=https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
  ]
}

variable "localai_port" {
  description = "Port to run LocalAI on"
  type        = number
  default     = 8080
}

variable "localai_threads" {
  description = "Number of threads to allocate to LocalAI"
  type        = number
  default     = 4
}

variable "localai_context_size" {
  description = "Context size for LocalAI models"
  type        = number
  default     = 2048
}

# Ollama Configuration
variable "install_ollama" {
  description = "Install Ollama on the GPU droplet"
  type        = bool
  default     = false
}

variable "ollama_model" {
  description = "Default Ollama model to download (e.g., 'llama2', 'mistral')"
  type        = string
  default     = "llama2"
}

variable "install_ollama_webui" {
  description = "Install Ollama Web UI"
  type        = bool
  default     = false
}

variable "ollama_port" {
  description = "Port to run Ollama on"
  type        = number
  default     = 11434
}

variable "project_name" {
  description = "Name of the DigitalOcean project to assign resources to"
  type        = string
  default     = ""
}

variable "create_snapshot_on_destroy" {
  description = "Create a snapshot of the droplet before destroying it"
  type        = bool
  default     = false
}

variable "snapshot_name" {
  description = "Name for the droplet snapshot (if not provided, will use droplet name with timestamp)"
  type        = string
  default     = ""
}

variable "allow_volume_destruction" {
  description = "Explicitly allow volume destruction even when protect_volume is true (use with caution)"
  type        = bool
  default     = false
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key file for connecting to the droplet"
  type        = string
  default     = "~/.ssh/id_rsa"
}
