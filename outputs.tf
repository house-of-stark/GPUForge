output "bucket_name" {
  description = "Name of the created Spaces bucket"
  value       = digitalocean_spaces_bucket.main.name
}

output "bucket_domain_name" {
  description = "Domain name of the Spaces bucket"
  value       = digitalocean_spaces_bucket.main.bucket_domain_name
}

output "bucket_urn" {
  description = "URN of the Spaces bucket"
  value       = digitalocean_spaces_bucket.main.urn
}

output "bucket_region" {
  description = "Region of the Spaces bucket"
  value       = digitalocean_spaces_bucket.main.region
}

output "cdn_endpoint" {
  description = "CDN endpoint URL (if enabled)"
  value       = var.enable_cdn ? digitalocean_cdn.main[0].endpoint : null
}

output "cdn_id" {
  description = "CDN ID (if enabled)"
  value       = var.enable_cdn ? digitalocean_cdn.main[0].id : null
}

output "bucket_endpoint" {
  description = "S3-compatible endpoint for the bucket"
  value       = "https://${var.region}.digitaloceanspaces.com"
}

# === ESSENTIAL INFORMATION ===
output "droplet_info" {
  description = "Essential droplet information with intelligent analysis"
  value = {
    connection = {
      ip_address  = module.gpu_droplet.droplet_ipv4
      floating_ip = module.gpu_droplet.floating_ip
      ssh_command = module.gpu_droplet.ssh_connection_info != null ? module.gpu_droplet.ssh_connection_info.ssh_command : null
    }
    
    gpu_specs = {
      model       = module.gpu_droplet.gpu_efficiency_analysis.performance_metrics.gpu_memory_gb != null ? var.gpu_size : "Not available"
      vram_gb     = module.gpu_droplet.gpu_efficiency_analysis.performance_metrics.gpu_memory_gb
      compute_units = module.gpu_droplet.gpu_efficiency_analysis.performance_metrics.compute_units
    }
    
    ai_services = {
      ollama_endpoint   = module.gpu_droplet.ollama_endpoint
      localai_endpoint  = module.gpu_droplet.localai_endpoint
      model_storage     = "/mnt/ai-models (volume-mounted)"
    }
  }
}

# === INTELLIGENT COST ANALYSIS ===
output "cost_analysis" {
  description = "Comprehensive cost analysis with efficiency recommendations"
  value = {
    current_costs = {
      hourly_cost   = module.gpu_droplet.cost_tracking.total_hourly_cost
      daily_cost    = module.gpu_droplet.cost_tracking.total_daily_cost
      monthly_cost  = module.gpu_droplet.cost_tracking.total_monthly_cost
    }
    
    efficiency_analysis = {
      performance_rank = module.gpu_droplet.gpu_efficiency_analysis.efficiency_rankings.by_performance
      cost_efficiency_rank = module.gpu_droplet.gpu_efficiency_analysis.efficiency_rankings.by_cost_efficiency
      memory_efficiency_rank = module.gpu_droplet.gpu_efficiency_analysis.efficiency_rankings.by_memory_efficiency
    }
    
    recommendations = module.gpu_droplet.gpu_efficiency_analysis.recommendations
  }
}

# === AI MODEL RECOMMENDATIONS ===
output "model_recommendations" {
  description = "GPU-optimized model recommendations with MCP tool awareness"
  value = {
    quick_start = {
      recommended_model = module.gpu_droplet.ollama_quick_start != null ? module.gpu_droplet.ollama_quick_start.recommended_first_model : "llama3.1:8b"
      setup_commands = module.gpu_droplet.ollama_quick_start != null ? module.gpu_droplet.ollama_quick_start.setup_commands : []
    }
    
    general_models = module.gpu_droplet.ollama_model_recommendations != null ? module.gpu_droplet.ollama_model_recommendations.general_models : []
    
    mcp_optimized = {
      best_for_mcp = module.gpu_droplet.mcp_tool_model_recommendations != null ? module.gpu_droplet.mcp_tool_model_recommendations.mcp_integration_guide.best_for_mcp : "llama3.1:8b"
      recommended_models = module.gpu_droplet.mcp_tool_model_recommendations != null ? module.gpu_droplet.mcp_tool_model_recommendations.recommended_models : []
    }
    
    specialized = module.gpu_droplet.ollama_model_recommendations != null ? module.gpu_droplet.ollama_model_recommendations.specialized_models : {}
  }
}

# === MANAGEMENT COMMANDS ===
output "management_guide" {
  description = "Complete management guide for your GPU droplet"
  value = {
    ssh_connection = module.gpu_droplet.ssh_connection_info
    
    ollama_management = {
      connection = module.gpu_droplet.ollama_management_commands != null ? module.gpu_droplet.ollama_management_commands.connection : null
      model_commands = module.gpu_droplet.ollama_management_commands != null ? module.gpu_droplet.ollama_management_commands.model_management : null
      monitoring = module.gpu_droplet.ollama_management_commands != null ? module.gpu_droplet.ollama_management_commands.monitoring : null
    }
    
    volume_management = module.gpu_droplet.volume_management_commands
    
    getting_started = {
      step_1 = "Connect: ${module.gpu_droplet.ssh_connection_info != null ? module.gpu_droplet.ssh_connection_info.ssh_command : "SSH info not available"}"
      step_2 = "Check GPU: nvidia-smi"
      step_3 = "Pull model: ollama pull ${module.gpu_droplet.ollama_quick_start != null ? module.gpu_droplet.ollama_quick_start.recommended_first_model : "llama3.1:8b"}"
      step_4 = "Test model: ollama run ${module.gpu_droplet.ollama_quick_start != null ? module.gpu_droplet.ollama_quick_start.recommended_first_model : "llama3.1:8b"}"
    }
  }
}

# GPU Droplet Outputs
output "gpu_droplet_id" {
  description = "ID of the GPU droplet (if created)"
  value       = var.create_gpu_droplet ? digitalocean_droplet.gpu_droplet[0].id : null
}

output "gpu_droplet_name" {
  description = "Name of the GPU droplet (if created)"
  value       = var.create_gpu_droplet ? digitalocean_droplet.gpu_droplet[0].name : null
}

output "gpu_droplet_ipv4_address" {
  description = "IPv4 address of the GPU droplet (if created)"
  value       = var.create_gpu_droplet ? digitalocean_droplet.gpu_droplet[0].ipv4_address : null
}

output "gpu_droplet_ipv4_address_private" {
  description = "Private IPv4 address of the GPU droplet (if created)"
  value       = var.create_gpu_droplet ? digitalocean_droplet.gpu_droplet[0].ipv4_address_private : null
}

output "gpu_droplet_ipv6_address" {
  description = "IPv6 address of the GPU droplet (if created)"
  value       = var.create_gpu_droplet && var.enable_ipv6 ? digitalocean_droplet.gpu_droplet[0].ipv6_address : null
}

output "gpu_droplet_floating_ip" {
  description = "Floating IP address of the GPU droplet (if created)"
  value       = var.create_gpu_droplet && var.create_floating_ip ? digitalocean_floating_ip.gpu_droplet_ip[0].ip_address : null
}

output "gpu_droplet_urn" {
  description = "URN of the GPU droplet (if created)"
  value       = var.create_gpu_droplet ? digitalocean_droplet.gpu_droplet[0].urn : null
}

output "gpu_droplet_region" {
  description = "Region of the GPU droplet (if created)"
  value       = var.create_gpu_droplet ? digitalocean_droplet.gpu_droplet[0].region : null
}

output "gpu_droplet_size" {
  description = "Size of the GPU droplet (if created)"
  value       = var.create_gpu_droplet ? digitalocean_droplet.gpu_droplet[0].size : null
}

output "gpu_droplet_volume_id" {
  description = "ID of the additional volume (if created)"
  value       = var.create_gpu_droplet && var.create_volume ? digitalocean_volume.gpu_droplet_volume[0].id : null
}

output "gpu_droplet_firewall_id" {
  description = "ID of the droplet firewall (if created)"
  value       = var.create_gpu_droplet && var.create_firewall ? digitalocean_firewall.gpu_droplet_firewall[0].id : null
}

output "ssh_connection_command" {
  description = "SSH command to connect to the GPU droplet (if created)"
  value = var.create_gpu_droplet ? (
    var.create_floating_ip ? 
    "ssh root@${digitalocean_floating_ip.gpu_droplet_ip[0].ip_address}" :
    "ssh root@${digitalocean_droplet.gpu_droplet[0].ipv4_address}"
  ) : null
}

output "access_instructions" {
  description = "Instructions for accessing the resources"
  value = <<-EOT
    ${length(digitalocean_spaces_bucket.main.name) > 0 ? "=== SPACES BUCKET ===" : ""}
    ${length(digitalocean_spaces_bucket.main.name) > 0 ? "- Web Interface: https://cloud.digitalocean.com/spaces" : ""}
    ${length(digitalocean_spaces_bucket.main.name) > 0 ? "- S3-Compatible Endpoint: https://${var.region}.digitaloceanspaces.com" : ""}
    ${length(digitalocean_spaces_bucket.main.name) > 0 ? "- Bucket URL: https://${digitalocean_spaces_bucket.main.name}.${var.region}.digitaloceanspaces.com" : ""}
    ${var.enable_cdn ? "- CDN URL: ${digitalocean_cdn.main[0].endpoint}" : ""}
    
    ${var.create_gpu_droplet ? "=== GPU DROPLET ===" : ""}
    ${var.create_gpu_droplet ? "- Droplet Name: ${digitalocean_droplet.gpu_droplet[0].name}" : ""}
    ${var.create_gpu_droplet ? "- GPU Type: ${digitalocean_droplet.gpu_droplet[0].size}" : ""}
    ${var.create_gpu_droplet ? "- Public IP: ${digitalocean_droplet.gpu_droplet[0].ipv4_address}" : ""}
    ${var.create_gpu_droplet && var.create_floating_ip ? "- Floating IP: ${digitalocean_floating_ip.gpu_droplet_ip[0].ip_address}" : ""}
    ${var.create_gpu_droplet ? "- SSH Command: ssh root@${var.create_floating_ip ? digitalocean_floating_ip.gpu_droplet_ip[0].ip_address : digitalocean_droplet.gpu_droplet[0].ipv4_address}" : ""}
    ${var.create_gpu_droplet && var.create_volume ? "- Additional Volume: ${digitalocean_volume.gpu_droplet_volume[0].size}GB mounted" : ""}
  EOT
}
