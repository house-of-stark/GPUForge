output "droplet_id" {
  description = "The ID of the created GPU droplet"
  value       = try(digitalocean_droplet.gpu[0].id, null)
}

output "droplet_name" {
  description = "The name of the created GPU droplet"
  value       = local.droplet_name
}

output "droplet_ipv4" {
  description = "The public IPv4 address of the GPU droplet"
  value       = try(digitalocean_droplet.gpu[0].ipv4_address, null)
}

output "droplet_ip" {
  description = "The public IP address of the droplet"
  value       = var.enabled && local.valid_gpu_size != null ? digitalocean_droplet.gpu[0].ipv4_address : null
}

output "droplet_ipv6" {
  description = "The public IPv6 address of the GPU droplet"
  value       = var.enable_ipv6 ? try(digitalocean_droplet.gpu[0].ipv6_address, null) : null
}

output "ssh_key_info" {
  description = "Information about SSH keys configured for the droplet"
  value = {
    auto_import_enabled = var.auto_import_ssh_keys
    manual_key_ids = var.ssh_key_ids
    requested_key_names = var.ssh_key_names
    final_key_ids = local.final_ssh_key_ids
    key_count = length(local.final_ssh_key_ids)
    key_source = length(var.ssh_key_ids) > 0 ? "Manual IDs" : (
      var.auto_import_ssh_keys ? (
        length(var.ssh_key_names) > 0 ? "Named keys from account" : "All keys from account"
      ) : "None configured"
    )
    private_key_path = var.ssh_private_key_path
  }
}

output "floating_ip" {
  description = "The floating IP assigned to the GPU droplet (if enabled)"
  value       = var.enable_floating_ip ? try(digitalocean_floating_ip.gpu_ip[0].ip_address, null) : null
}

output "volume_id" {
  description = "The ID of the attached volume (if enabled)"
  value       = var.volume_size_gb > 0 ? try(digitalocean_volume.gpu_volume[0].id, null) : null
}

output "model_storage_info" {
  description = "AI model storage configuration and paths"
  value = var.volume_size_gb > 0 ? {
    volume_enabled = true
    mount_point = "/mnt/ai-models"
    ollama_models_path = "/mnt/ai-models/ollama/models"
    localai_models_path = "/mnt/ai-models/localai/models"
    shared_models_path = "/mnt/ai-models/shared/models"
    volume_size_gb = var.volume_size_gb
    filesystem = var.volume_filesystem
    protection_enabled = var.protect_volume
    destruction_allowed = var.allow_volume_destruction
    snapshot_on_destroy = var.create_volume_snapshot_on_destroy
    management_commands = {
      check_storage = "df -h /mnt/ai-models"
      list_ollama_models = "ls -la /mnt/ai-models/ollama/models/"
      list_localai_models = "ls -la /mnt/ai-models/localai/models/"
      manage_ollama = "/root/manage_ollama_models.sh"
      manage_localai = "/root/manage_localai_models.sh"
    }
  } : {
    volume_enabled = false
    warning = "No volume attached - models will be stored on root filesystem"
    ollama_models_path = "/usr/share/ollama/.ollama/models" 
    localai_models_path = "/opt/localai/models"
    protection_enabled = false
  }
}

output "firewall_id" {
  description = "The ID of the created firewall (if enabled)"
  value       = var.enable_firewall ? try(digitalocean_firewall.gpu_firewall[0].id, null) : null
}

output "cost_estimate" {
  description = "Comprehensive cost information for the GPU droplet across all time periods"
  value = {
    # Total costs across all time periods
    hourly_total   = local.total_hourly_cost
    daily_total    = local.total_daily_cost
    monthly_total  = local.total_monthly_cost
    
    # Detailed breakdown by component and time period
    breakdown = {
      gpu_droplet = {
        hourly  = local.gpu_hourly_cost
        daily   = local.gpu_daily_cost
        monthly = local.gpu_monthly_cost
      }
      floating_ip = {
        hourly  = local.floating_ip_hourly_cost
        daily   = local.floating_ip_daily_cost
        monthly = local.floating_ip_monthly_cost
      }
      backups = {
        hourly  = local.backup_hourly_cost
        daily   = local.backup_daily_cost
        monthly = local.backup_monthly_cost
      }
      storage = {
        hourly  = local.volume_hourly_cost
        daily   = local.volume_daily_cost
        monthly = local.volume_monthly_cost
      }
    }
    
    # Legacy fields for backward compatibility
    hourly_rate      = local.total_hourly_cost
    monthly_estimate = local.total_monthly_cost
  }
}

output "cost_log_path" {
  description = "Path to the cost log file"
  value       = var.enable_cost_tracking ? "${path.root}/cost_logs/${local.droplet_name}_costs.json" : null
}

# GPU Efficiency Analysis Outputs
output "gpu_efficiency_analysis" {
  description = "Comprehensive GPU efficiency analysis and rankings for the current region"
  value = {
    region = var.region
    analysis_timestamp = timestamp()
    
    # Available GPU specifications in this region
    available_gpus = local.available_gpu_specs
    
    # Efficiency rankings by different criteria
    rankings = local.efficiency_rankings
    
    # Use case recommendations
    recommendations = local.gpu_recommendations
    
    # Quick summary of best options
    best_options = {
      best_value_overall = try([
        for gpu_size, ranking in local.efficiency_rankings.performance_per_dollar :
        {
          gpu_size = gpu_size
          model = local.available_gpu_specs[gpu_size].gpu_model
          efficiency = ranking.description
          hourly_cost = "$${format("%.2f", local.available_gpu_specs[gpu_size].hourly)}/hour"
        }
        if ranking.rank == 1
      ][0], null)
      
      best_memory_value = try([
        for gpu_size, ranking in local.efficiency_rankings.memory_per_dollar :
        {
          gpu_size = gpu_size
          model = local.available_gpu_specs[gpu_size].gpu_model
          efficiency = ranking.description
          hourly_cost = "$${format("%.2f", local.available_gpu_specs[gpu_size].hourly)}/hour"
        }
        if ranking.rank == 1
      ][0], null)
      
      lowest_cost = try([
        for gpu_size, ranking in local.efficiency_rankings.lowest_cost :
        {
          gpu_size = gpu_size
          model = local.available_gpu_specs[gpu_size].gpu_model
          cost = ranking.description
          performance = "${format("%.0f", local.available_gpu_specs[gpu_size].tensor_performance_fp16)} TFLOPS"
        }
        if ranking.rank == 1
      ][0], null)
      
      highest_performance = try([
        for gpu_size, ranking in local.efficiency_rankings.absolute_performance :
        {
          gpu_size = gpu_size
          model = local.available_gpu_specs[gpu_size].gpu_model
          performance = ranking.description
          hourly_cost = "$${format("%.2f", local.available_gpu_specs[gpu_size].hourly)}/hour"
        }
        if ranking.rank == 1
      ][0], null)
    }
  }
}

output "ollama_endpoint" {
  description = "Ollama API endpoint (if installed)"
  value       = var.install_ollama ? "http://${digitalocean_droplet.gpu[0].ipv4_address}:${var.ollama_port}" : null
}

output "ollama_model_storage" {
  description = "Ollama model storage location and management"
  value = var.install_ollama ? {
    models_path = var.volume_size_gb > 0 ? "/mnt/ai-models/ollama/models" : "/usr/share/ollama/.ollama/models"
    using_volume = var.volume_size_gb > 0
    management_script = "/root/manage_ollama_models.sh"
    test_script = "/root/test_ollama.sh"
  } : null
}

output "ollama_webui_url" {
  description = "Ollama Web UI URL (if installed)"
  value       = (var.install_ollama && var.install_ollama_webui) ? "http://${digitalocean_droplet.gpu[0].ipv4_address}:3000" : null
}

output "ollama_ssh_command" {
  description = "SSH command to test Ollama installation"
  value       = var.install_ollama ? "ssh root@${digitalocean_droplet.gpu[0].ipv4_address} '/root/test_ollama.sh'" : null
}

output "test_ssh_command" {
  description = "SSH command to connect to the droplet"
  value       = var.enabled && local.valid_gpu_size != null ? "ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.gpu[0].ipv4_address}" : null
}

output "ssh_connection_info" {
  description = "Complete SSH connection information and troubleshooting"
  value = var.enabled && local.valid_gpu_size != null ? {
    ip_address = digitalocean_droplet.gpu[0].ipv4_address
    username = "root"
    private_key_path = var.ssh_private_key_path
    ssh_command = "ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.gpu[0].ipv4_address}"
    configured_keys = length(local.final_ssh_key_ids)
    key_source = length(var.ssh_key_ids) > 0 ? "Manual" : "Auto-imported from DigitalOcean account"
    troubleshooting = {
      check_key_permissions = "chmod 600 ${var.ssh_private_key_path}"
      test_connection = "ssh -i ${var.ssh_private_key_path} -o ConnectTimeout=10 root@${digitalocean_droplet.gpu[0].ipv4_address} 'echo Connection successful'"
      list_authorized_keys = "ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.gpu[0].ipv4_address} 'cat ~/.ssh/authorized_keys'"
    }
  } : null
}

output "volume_management_commands" {
  description = "Commands for managing the attached volume and model storage"
  value = var.volume_size_gb > 0 ? {
    check_mount = "ssh root@${try(digitalocean_droplet.gpu[0].ipv4_address, "DROPLET_IP")} 'df -h /mnt/ai-models'"
    check_models = "ssh root@${try(digitalocean_droplet.gpu[0].ipv4_address, "DROPLET_IP")} 'ls -la /mnt/ai-models/*/models/'"
    manage_ollama = "ssh root@${try(digitalocean_droplet.gpu[0].ipv4_address, "DROPLET_IP")} '/root/manage_ollama_models.sh'"
    manage_localai = "ssh root@${try(digitalocean_droplet.gpu[0].ipv4_address, "DROPLET_IP")} '/root/manage_localai_models.sh'"
  } : null
}

# Snapshot Configuration Outputs
output "snapshot_config" {
  description = "Snapshot configuration and status"
  value = {
    enabled = var.create_snapshot_on_destroy
    snapshot_name = var.snapshot_name != "" ? var.snapshot_name : "${local.droplet_name}-snapshot-[timestamp]"
    droplet_name = local.droplet_name
    droplet_id = var.enabled && local.valid_gpu_size != null ? digitalocean_droplet.gpu[0].id : null
    snapshot_directory = "${path.root}/snapshots"
    requirements = {
      doctl_installed = "Required for snapshot creation"
      doctl_authenticated = "Run 'doctl auth init' to authenticate"
    }
    cost_info = {
      storage_cost = "$0.05/GB/month for snapshot storage"
      estimated_size = "20GB+ for GPU droplets with software installed"
    }
  }
}

output "snapshot_management_commands" {
  description = "Useful commands for managing snapshots"
  value = var.create_snapshot_on_destroy ? {
    list_snapshots = "doctl compute snapshot list"
    create_from_snapshot = "doctl compute droplet create my-restored-droplet --image <snapshot-id> --size ${var.gpu_size} --region ${var.region} --ssh-keys <ssh-key-id>"
    delete_snapshot = "doctl compute snapshot delete <snapshot-id>"
    view_snapshot_logs = "ls -la ${path.root}/snapshots/"
  } : null
}

output "volume_protection_info" {
  description = "Volume protection and lifecycle management information"
  value = var.volume_size_gb > 0 ? {
    volume_id = digitalocean_volume.gpu_volume[0].id
    volume_name = digitalocean_volume.gpu_volume[0].name
    protection_status = {
      enabled = var.protect_volume
      destruction_allowed = var.allow_volume_destruction
      will_survive_destroy = var.protect_volume && !var.allow_volume_destruction
      snapshot_on_destroy = var.create_volume_snapshot_on_destroy
    }
    data_safety = {
      ai_models_protected = var.protect_volume && !var.allow_volume_destruction
      backup_strategy = var.create_volume_snapshot_on_destroy ? "Volume snapshot before destroy" : "No automatic backup"
      risk_level = (!var.protect_volume || var.allow_volume_destruction) ? "HIGH - Data will be lost on destroy" : "LOW - Data protected"
    }
    management_commands = {
      list_volumes = "doctl compute volume list"
      create_volume_snapshot = "doctl compute volume-action snapshot ${digitalocean_volume.gpu_volume[0].id} --snapshot-name my-volume-backup"
      list_volume_snapshots = "doctl compute volume-snapshot list"
      restore_from_snapshot = "doctl compute volume create restored-volume --size ${var.volume_size_gb} --region ${var.region} --snapshot <snapshot-id>"
    }
    cost_info = {
      volume_monthly_cost = "$${format("%.2f", var.volume_size_gb * 0.10)}"
      snapshot_storage_cost = "$0.05/GB/month for volume snapshots"
      protection_value = "Prevents loss of potentially $1000s in AI model downloads and training"
    }
  } : {
    volume_attached = false
    protection_status = "No volume to protect"
  }
}

output "valid_gpu_size" {
  description = "The validated GPU size that will be used"
  value       = local.valid_gpu_size
}

output "storage_summary" {
  description = "Complete storage configuration summary"
  value = {
    volume_attached = var.volume_size_gb > 0
    volume_size_gb = var.volume_size_gb
    volume_filesystem = var.volume_filesystem
    ai_models_mount = var.volume_size_gb > 0 ? "/mnt/ai-models" : "Not configured"
    volume_protection = {
      enabled = var.protect_volume
      destruction_allowed = var.allow_volume_destruction
      will_be_destroyed = var.volume_size_gb > 0 ? (!var.protect_volume || var.allow_volume_destruction) : false
      snapshot_on_destroy = var.create_volume_snapshot_on_destroy
      warning = (!var.protect_volume || var.allow_volume_destruction) && var.volume_size_gb > 0 ? "⚠️  Volume will be DESTROYED on terraform destroy - AI models will be lost!" : null
    }
    model_storage = {
      ollama = var.install_ollama ? (var.volume_size_gb > 0 ? "/mnt/ai-models/ollama/models" : "System default") : "Not installed"
      localai = var.install_localai ? (var.volume_size_gb > 0 ? "/mnt/ai-models/localai/models" : "System default") : "Not installed"
    }
    estimated_monthly_cost = var.volume_size_gb > 0 ? "$${format("%.2f", var.volume_size_gb * 0.10)}" : "$0.00"
  }
}

output "region_availability" {
  description = "Information about GPU availability in the selected region"
  value = {
    region           = var.region
    available_gpus = lookup(local.available_gpus, var.region, [])
    supported_regions = keys(local.available_gpus)
  }
}

output "volume_snapshot_config" {
  description = "Volume snapshot configuration and status"
  value = var.create_volume_snapshot_on_destroy && var.volume_size_gb > 0 ? {
    enabled = true
    snapshot_name = var.volume_snapshot_name != "" ? var.volume_snapshot_name : "${var.name}-volume-snapshot-[timestamp]"
    volume_id = digitalocean_volume.gpu_volume[0].id
    snapshot_directory = "${path.root}/volume-snapshots"
    requirements = {
      doctl_installed = "Required for volume snapshot creation"
      doctl_authenticated = "Run 'doctl auth init' to authenticate"
    }
    restore_commands = {
      list_snapshots = "doctl compute volume-snapshot list"
      create_volume_from_snapshot = "doctl compute volume create restored-ai-models --size ${var.volume_size_gb} --region ${var.region} --snapshot <snapshot-id>"
      attach_to_droplet = "Modify Terraform config to use restored volume ID"
    }
  } : {
    enabled = false
    reason = var.volume_size_gb == 0 ? "No volume attached" : "Volume snapshot on destroy not enabled"
  }
}

output "account_ssh_keys" {
  description = "SSH keys available in your DigitalOcean account (when auto-import is enabled)"
  value = var.auto_import_ssh_keys && length(var.ssh_key_ids) == 0 ? {
    all_keys = try([
      for key in data.digitalocean_ssh_keys.account_keys[0].ssh_keys : {
        id = key.id
        name = key.name
        fingerprint = key.fingerprint
        public_key_preview = "${substr(key.public_key, 0, 50)}..."
      }
    ], [])
    selected_keys = length(var.ssh_key_names) > 0 ? [
      for key in data.digitalocean_ssh_key.named_keys : {
        id = key.id
        name = key.name
        fingerprint = key.fingerprint
        public_key_preview = "${substr(key.public_key, 0, 50)}..."
      }
    ] : try([
      for key in data.digitalocean_ssh_keys.account_keys[0].ssh_keys : {
        id = key.id
        name = key.name
        fingerprint = key.fingerprint
        public_key_preview = "${substr(key.public_key, 0, 50)}..."
      }
    ], [])
    total_keys_in_account = try(length(data.digitalocean_ssh_keys.account_keys[0].ssh_keys), 0)
    keys_used_for_droplet = length(local.final_ssh_key_ids)
  } : {
    auto_import_disabled = true
    message = "Enable auto_import_ssh_keys = true to see account SSH keys"
  }
}

# Ollama Model Recommendations Based on GPU VRAM
output "ollama_model_recommendations" {
  description = "Ollama model recommendations optimized for your GPU's VRAM capacity"
  value = local.ollama_model_recommendations
}

output "ollama_quick_start" {
  description = "Quick start guide for Ollama models on your GPU droplet"
  value = local.ollama_model_recommendations != null ? {
    gpu_info = local.ollama_model_recommendations.gpu_info
    recommended_first_model = local.ollama_model_recommendations.quick_start.recommended_first_model
    setup_commands = local.ollama_model_recommendations.quick_start.setup_commands
    optimization_tips = local.ollama_model_recommendations.optimization_tips.quantization_guide
  } : null
}

output "mcp_tool_model_recommendations" {
  description = "Specialized Ollama model recommendations for MCP Tool integration"
  value = local.ollama_model_recommendations != null ? {
    gpu_vram_gb = local.ollama_model_recommendations.gpu_info.vram_gb
    recommended_models = local.ollama_model_recommendations.mcp_tool_models
    
    mcp_integration_guide = {
      best_for_mcp = length(local.ollama_model_recommendations.mcp_tool_models) > 0 ? local.ollama_model_recommendations.mcp_tool_models[0].name : "llama3.1:8b"
      function_calling_setup = "Configure Ollama with function calling enabled for optimal MCP tool usage"
      structured_output_tips = "Use system prompts that emphasize JSON formatting and tool usage patterns"
      embedding_model = "nomic-embed-text - Essential for RAG and semantic search in MCP workflows"
    }
    
    mcp_workflow_examples = {
      development = "Use CodeLlama models for code analysis, generation, and debugging with MCP tools"
      data_analysis = "Combine Llama3.1 with embedding models for document analysis and RAG workflows"
      automation = "Leverage function calling capabilities for automated task execution via MCP"
    }
    
    performance_considerations = {
      concurrent_usage = local.ollama_model_recommendations.optimization_tips.concurrent_models
      batch_processing = local.ollama_model_recommendations.optimization_tips.batch_processing
      quantization_for_mcp = "Q4_K_M or Q5_K_M recommended for best balance of speed and tool calling accuracy"
    }
  } : null
}

# Model Management and Usage Commands
output "ollama_management_commands" {
  description = "Commands for managing Ollama models on your GPU droplet"
  value = var.enabled && local.valid_gpu_size != null ? {
    connection = {
      ssh_command = "ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.gpu[0].ipv4_address}"
      ollama_endpoint = "http://${digitalocean_droplet.gpu[0].ipv4_address}:11434"
    }
    
    model_management = {
      list_models = "ollama list"
      pull_model = "ollama pull MODEL_NAME"
      remove_model = "ollama rm MODEL_NAME"
      show_model_info = "ollama show MODEL_NAME"
    }
    
    usage_examples = {
      interactive_chat = "ollama run MODEL_NAME"
      api_request = "curl http://localhost:11434/api/generate -d '{\"model\": \"MODEL_NAME\", \"prompt\": \"Hello!\"}'"
      streaming_response = "curl http://localhost:11434/api/generate -d '{\"model\": \"MODEL_NAME\", \"prompt\": \"Hello!\", \"stream\": true}'"
    }
    
    monitoring = {
      check_gpu_usage = "nvidia-smi"
      check_ollama_status = "systemctl status ollama"
      view_ollama_logs = "journalctl -u ollama -f"
      check_disk_usage = "df -h /mnt/ai-models"
    }
    
    troubleshooting = {
      restart_ollama = "systemctl restart ollama"
      check_gpu_memory = "nvidia-smi --query-gpu=memory.used,memory.total --format=csv"
      clear_model_cache = "ollama rm $(ollama list -q)"
      check_model_storage = "ls -la /mnt/ai-models/ollama/models/"
    }
  } : null
}
