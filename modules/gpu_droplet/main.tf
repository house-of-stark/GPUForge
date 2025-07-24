# GPU Droplet Module
# This module creates a GPU droplet with cost tracking and flexible configuration

locals {
  # Current DigitalOcean GPU Droplet Pricing with Performance Specifications (as of 2024)
  gpu_specifications = {
    "gpu-h100x1-80gb" = {
      # Pricing
      hourly = 4.464
      monthly = 4.464 * 24 * 30.44
      # Performance Specifications
      gpu_count = 1
      gpu_memory_gb = 80
      gpu_model = "NVIDIA H100"
      tensor_performance_fp16 = 1979  # TFLOPS
      tensor_performance_bf16 = 1979  # TFLOPS
      tensor_performance_fp8 = 3958   # TFLOPS
      memory_bandwidth_gbps = 3350
      nvlink_bandwidth_gbps = 900
      # Efficiency metrics (performance per dollar per hour)
      tensor_fp16_per_dollar_hour = 1979 / 4.464
      memory_gb_per_dollar_hour = 80 / 4.464
      use_cases = ["Large Language Models", "Training", "High-Performance Inference"]
    }
    "gpu-h100x8-640gb" = {
      # Pricing
      hourly = 35.712
      monthly = 35.712 * 24 * 30.44
      # Performance Specifications
      gpu_count = 8
      gpu_memory_gb = 640
      gpu_model = "NVIDIA H100"
      tensor_performance_fp16 = 15832  # TFLOPS (8x GPUs)
      tensor_performance_bf16 = 15832  # TFLOPS
      tensor_performance_fp8 = 31664   # TFLOPS
      memory_bandwidth_gbps = 26800    # 8x GPUs
      nvlink_bandwidth_gbps = 7200     # 8x GPUs
      # Efficiency metrics
      tensor_fp16_per_dollar_hour = 15832 / 35.712
      memory_gb_per_dollar_hour = 640 / 35.712
      use_cases = ["Distributed Training", "Large Model Inference", "Multi-GPU Workloads"]
    }
    "gpu-mi300x1-192gb" = {
      # Pricing
      hourly = 3.20
      monthly = 3.20 * 24 * 30.44
      # Performance Specifications
      gpu_count = 1
      gpu_memory_gb = 192
      gpu_model = "AMD MI300X"
      tensor_performance_fp16 = 1307  # TFLOPS
      tensor_performance_bf16 = 1307  # TFLOPS
      tensor_performance_fp8 = 2614   # TFLOPS
      memory_bandwidth_gbps = 5200
      # Efficiency metrics
      tensor_fp16_per_dollar_hour = 1307 / 3.20
      memory_gb_per_dollar_hour = 192 / 3.20
      use_cases = ["Large Memory Models", "Cost-Effective Training", "Memory-Intensive Workloads"]
    }
    "gpu-mi300x8-1536gb" = {
      # Pricing
      hourly = 25.60
      monthly = 25.60 * 24 * 30.44
      # Performance Specifications
      gpu_count = 8
      gpu_memory_gb = 1536
      gpu_model = "AMD MI300X"
      tensor_performance_fp16 = 10456  # TFLOPS (8x GPUs)
      tensor_performance_bf16 = 10456  # TFLOPS
      tensor_performance_fp8 = 20912   # TFLOPS
      memory_bandwidth_gbps = 41600    # 8x GPUs
      # Efficiency metrics
      tensor_fp16_per_dollar_hour = 10456 / 25.60
      memory_gb_per_dollar_hour = 1536 / 25.60
      use_cases = ["Ultra-Large Models", "Memory-Heavy Distributed Training", "Cost-Effective Multi-GPU"]
    }
    "gpu-rtx4000x1-20gb" = {
      # Pricing
      hourly = 0.60
      monthly = 0.60 * 24 * 30.44
      # Performance Specifications
      gpu_count = 1
      gpu_memory_gb = 20
      gpu_model = "NVIDIA RTX 4000 Ada"
      tensor_performance_fp16 = 191   # TFLOPS
      tensor_performance_bf16 = 191   # TFLOPS
      memory_bandwidth_gbps = 717
      # Efficiency metrics
      tensor_fp16_per_dollar_hour = 191 / 0.60
      memory_gb_per_dollar_hour = 20 / 0.60
      use_cases = ["Development", "Small Models", "Prototyping", "Budget Inference"]
    }
    "gpu-rtx6000x1-48gb" = {
      # Pricing
      hourly = 1.20
      monthly = 1.20 * 24 * 30.44
      # Performance Specifications
      gpu_count = 1
      gpu_memory_gb = 48
      gpu_model = "NVIDIA RTX 6000 Ada"
      tensor_performance_fp16 = 273   # TFLOPS
      tensor_performance_bf16 = 273   # TFLOPS
      memory_bandwidth_gbps = 960
      # Efficiency metrics
      tensor_fp16_per_dollar_hour = 273 / 1.20
      memory_gb_per_dollar_hour = 48 / 1.20
      use_cases = ["Mid-Range Training", "Professional Inference", "Content Creation"]
    }
  }
  
  # Legacy pricing structure for backward compatibility
  gpu_pricing = {
    for k, v in local.gpu_specifications : k => {
      hourly = v.hourly
      monthly = v.monthly
    }
  }
  
  # Available GPU configurations by region
  # This would ideally be populated by a data source or API call
  # Static map of available GPUs by region based on DigitalOcean documentation
  # GPU droplets are primarily available in NYC2, TOR1, and ATL1
  available_gpus = {
    "nyc1" = [], # No GPU droplets available
    "nyc2" = ["gpu-h100x1-80gb", "gpu-h100x8-640gb", "gpu-mi300x1-192gb", "gpu-mi300x8-1536gb", "gpu-rtx4000x1-20gb", "gpu-rtx6000x1-48gb"],
    "nyc3" = [], # No GPU droplets available
    "tor1" = ["gpu-h100x1-80gb", "gpu-h100x8-640gb", "gpu-mi300x1-192gb", "gpu-mi300x8-1536gb", "gpu-rtx4000x1-20gb", "gpu-rtx6000x1-48gb"],
    "atl1" = ["gpu-h100x1-80gb", "gpu-h100x8-640gb", "gpu-mi300x1-192gb", "gpu-mi300x8-1536gb", "gpu-rtx4000x1-20gb", "gpu-rtx6000x1-48gb"],
    "sfo3" = [], # No GPU droplets available
    "ams3" = [], # No GPU droplets available
    "sgp1" = [], # No GPU droplets available
    "lon1" = [], # No GPU droplets available
    "fra1" = [], # No GPU droplets available
    "blr1" = [], # No GPU droplets available
    "syd1" = []  # No GPU droplets available
  }
  
  # Validate the requested GPU size is available in the selected region
  valid_gpu_size = contains(lookup(local.available_gpus, var.region, []), var.gpu_size) ? var.gpu_size : null
  
  # Calculate GPU costs
  gpu_hourly_cost  = local.valid_gpu_size != null ? local.gpu_pricing[local.valid_gpu_size].hourly : 0
  gpu_monthly_cost = local.valid_gpu_size != null ? local.gpu_pricing[local.valid_gpu_size].monthly : 0
  gpu_daily_cost   = local.gpu_hourly_cost * 24
  
  # Ollama model recommendations based on GPU VRAM
  ollama_model_recommendations = local.valid_gpu_size != null ? {
    gpu_info = {
      model = local.valid_gpu_size
      vram_gb = local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb
      compute_units = local.gpu_specifications[local.valid_gpu_size].gpu_count
      tensor_cores = local.gpu_specifications[local.valid_gpu_size].tensor_performance_fp16
    }
    
    # General purpose models by VRAM capacity
    general_models = local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 80 ? [
      {
        name = "llama3.1:70b"
        size = "70B parameters"
        vram_usage = "~40-50GB"
        use_case = "Large-scale reasoning, complex tasks, production workloads"
        quantization = "Q4_K_M recommended for best quality/speed balance"
        command = "ollama pull llama3.1:70b"
      },
      {
        name = "codellama:70b"
        size = "70B parameters"
        vram_usage = "~40-50GB"
        use_case = "Advanced code generation, large codebase analysis"
        quantization = "Q4_K_M for optimal performance"
        command = "ollama pull codellama:70b"
      },
      {
        name = "mixtral:8x22b"
        size = "8x22B MoE"
        vram_usage = "~45-60GB"
        use_case = "Multi-domain expertise, complex reasoning"
        quantization = "Q4_K_M recommended"
        command = "ollama pull mixtral:8x22b"
      }
    ] : local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 40 ? [
      {
        name = "llama3.1:33b"
        size = "33B parameters"
        vram_usage = "~20-25GB"
        use_case = "High-quality reasoning, good balance of speed and capability"
        quantization = "Q4_K_M or Q5_K_M for better quality"
        command = "ollama pull llama3.1:33b"
      },
      {
        name = "codellama:34b"
        size = "34B parameters"
        vram_usage = "~20-25GB"
        use_case = "Professional code generation, code review"
        quantization = "Q4_K_M recommended"
        command = "ollama pull codellama:34b"
      },
      {
        name = "mixtral:8x7b"
        size = "8x7B MoE"
        vram_usage = "~26-30GB"
        use_case = "Efficient multi-domain model, good for various tasks"
        quantization = "Q4_K_M for optimal balance"
        command = "ollama pull mixtral:8x7b"
      }
    ] : local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 20 ? [
      {
        name = "llama3.1:13b"
        size = "13B parameters"
        vram_usage = "~8-10GB"
        use_case = "Good general purpose model, fast inference"
        quantization = "Q4_K_M or Q5_K_M"
        command = "ollama pull llama3.1:13b"
      },
      {
        name = "codellama:13b"
        size = "13B parameters"
        vram_usage = "~8-10GB"
        use_case = "Code generation, debugging, explanation"
        quantization = "Q4_K_M recommended"
        command = "ollama pull codellama:13b"
      },
      {
        name = "llama3.1:8b"
        size = "8B parameters"
        vram_usage = "~5-6GB"
        use_case = "Fast inference, good for development and testing"
        quantization = "Q4_K_M, Q5_K_M, or Q6_K for higher quality"
        command = "ollama pull llama3.1:8b"
      }
    ] : [
      {
        name = "llama3.1:8b"
        size = "8B parameters"
        vram_usage = "~5-6GB"
        use_case = "Efficient model for smaller GPUs"
        quantization = "Q4_0 for maximum efficiency"
        command = "ollama pull llama3.1:8b"
      },
      {
        name = "phi3:14b"
        size = "14B parameters"
        vram_usage = "~8-9GB"
        use_case = "Microsoft's efficient model, good reasoning"
        quantization = "Q4_K_M recommended"
        command = "ollama pull phi3:14b"
      },
      {
        name = "gemma2:9b"
        size = "9B parameters"
        vram_usage = "~6-7GB"
        use_case = "Google's efficient model, good performance"
        quantization = "Q4_K_M or Q5_K_M"
        command = "ollama pull gemma2:9b"
      }
    ]
    
    # MCP Tool-aware model recommendations
    mcp_tool_models = local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 40 ? [
      {
        name = "llama3.1:33b"
        size = "33B parameters"
        vram_usage = "~20-25GB"
        mcp_capabilities = "Excellent function calling, tool usage, and structured output"
        use_case = "Advanced MCP tool integration, complex workflows"
        tool_calling_quality = "Excellent - Native function calling support"
        structured_output = "Very good JSON and structured data generation"
        command = "ollama pull llama3.1:33b"
        mcp_setup = "Configure with function calling enabled for optimal tool usage"
      },
      {
        name = "codellama:34b"
        size = "34B parameters"
        vram_usage = "~20-25GB"
        mcp_capabilities = "Strong code analysis and generation with tool integration"
        use_case = "Development workflows, code analysis with MCP tools"
        tool_calling_quality = "Very good - Understands API structures well"
        structured_output = "Excellent for code-related structured outputs"
        command = "ollama pull codellama:34b"
        mcp_setup = "Ideal for development-focused MCP tool chains"
      }
    ] : local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 20 ? [
      {
        name = "llama3.1:13b"
        size = "13B parameters"
        vram_usage = "~8-10GB"
        mcp_capabilities = "Good function calling and tool usage capabilities"
        use_case = "Standard MCP workflows, balanced performance"
        tool_calling_quality = "Good - Reliable function calling"
        structured_output = "Good JSON generation and parsing"
        command = "ollama pull llama3.1:13b"
        mcp_setup = "Recommended for most MCP use cases"
      },
      {
        name = "llama3.1:8b"
        size = "8B parameters"
        vram_usage = "~5-6GB"
        mcp_capabilities = "Basic tool usage, fast inference for simple MCP tasks"
        use_case = "Lightweight MCP integration, development testing"
        tool_calling_quality = "Fair - Basic function calling support"
        structured_output = "Adequate for simple structured outputs"
        command = "ollama pull llama3.1:8b"
        mcp_setup = "Good for testing MCP integrations"
      }
    ] : [
      {
        name = "llama3.1:8b"
        size = "8B parameters"
        vram_usage = "~5-6GB"
        mcp_capabilities = "Basic MCP tool integration for smaller GPUs"
        use_case = "Entry-level MCP workflows"
        tool_calling_quality = "Basic - Limited but functional"
        structured_output = "Basic JSON support"
        command = "ollama pull llama3.1:8b"
        mcp_setup = "Use Q4_0 quantization for maximum efficiency"
      }
    ]
    
    # Specialized models for specific use cases
    specialized_models = {
      embedding = {
        name = "nomic-embed-text"
        size = "137M parameters"
        vram_usage = "~1GB"
        use_case = "Text embeddings, semantic search, RAG systems"
        command = "ollama pull nomic-embed-text"
      }
      vision = local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 20 ? {
        name = "llava:13b"
        size = "13B parameters"
        vram_usage = "~8-10GB"
        use_case = "Vision-language tasks, image analysis"
        command = "ollama pull llava:13b"
      } : {
        name = "llava:7b"
        size = "7B parameters"
        vram_usage = "~5-6GB"
        use_case = "Basic vision-language tasks"
        command = "ollama pull llava:7b"
      }
      math = {
        name = "deepseek-math:7b"
        size = "7B parameters"
        vram_usage = "~5-6GB"
        use_case = "Mathematical reasoning and problem solving"
        command = "ollama pull deepseek-math:7b"
      }
    }
    
    # Performance optimization recommendations
    optimization_tips = {
      quantization_guide = {
        q4_0 = "Fastest inference, lowest quality - Use for development/testing"
        q4_k_m = "Best balance of speed and quality - Recommended for most use cases"
        q5_k_m = "Higher quality, slightly slower - Good for production workloads"
        q6_k = "Near-original quality, slower inference - Use when quality is critical"
        q8_0 = "Highest quality, slowest inference - Use only if VRAM allows"
      }
      
      concurrent_models = local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 40 ? 
        "Can run 2-3 smaller models simultaneously (e.g., llama3.1:8b + nomic-embed-text + llava:7b)" :
        local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 20 ?
        "Can run 1 main model + embedding model simultaneously" :
        "Recommended to run one model at a time for optimal performance"
      
      batch_processing = local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 40 ?
        "Supports large batch sizes (32-64) for efficient throughput" :
        "Use moderate batch sizes (8-16) for balanced performance"
    }
    
    # Quick start commands
    quick_start = {
      recommended_first_model = local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 40 ? "llama3.1:33b" :
        local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 20 ? "llama3.1:13b" : "llama3.1:8b"
      
      setup_commands = [
        "# Connect to your droplet",
        "ssh -i ${var.ssh_private_key_path} root@${var.enabled && local.valid_gpu_size != null ? digitalocean_droplet.gpu[0].ipv4_address : "DROPLET_IP"}",
        "",
        "# Pull recommended model",
        "ollama pull ${local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 40 ? "llama3.1:33b" : local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 20 ? "llama3.1:13b" : "llama3.1:8b"}",
        "",
        "# Test the model",
        "ollama run ${local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 40 ? "llama3.1:33b" : local.gpu_specifications[local.valid_gpu_size].gpu_memory_gb >= 20 ? "llama3.1:13b" : "llama3.1:8b"} \"Hello! Can you help me with coding tasks?\"",
        "",
        "# For MCP integration, also pull:",
        "ollama pull nomic-embed-text  # For embeddings and RAG"
      ]
    }
  } : null
  
  # Additional costs (monthly rates)
  floating_ip_monthly_cost = var.enable_floating_ip ? 6.00 : 0  # $6/month for floating IP
  backup_monthly_cost = var.enable_backups ? local.gpu_monthly_cost * 0.20 : 0  # 20% of droplet cost for backups
  volume_monthly_cost = var.volume_size_gb > 0 ? var.volume_size_gb * 0.10 : 0  # $0.10/GB/month
  
  # Convert additional costs to hourly and daily rates (assuming 30.44 days per month average)
  floating_ip_hourly_cost = local.floating_ip_monthly_cost / (30.44 * 24)
  floating_ip_daily_cost  = local.floating_ip_monthly_cost / 30.44
  backup_hourly_cost      = local.backup_monthly_cost / (30.44 * 24)
  backup_daily_cost       = local.backup_monthly_cost / 30.44
  volume_hourly_cost      = local.volume_monthly_cost / (30.44 * 24)
  volume_daily_cost       = local.volume_monthly_cost / 30.44
  
  # Total costs across all time periods
  total_hourly_cost  = local.gpu_hourly_cost + local.floating_ip_hourly_cost + local.backup_hourly_cost + local.volume_hourly_cost
  total_daily_cost   = local.gpu_daily_cost + local.floating_ip_daily_cost + local.backup_daily_cost + local.volume_daily_cost
  total_monthly_cost = local.gpu_monthly_cost + local.floating_ip_monthly_cost + local.backup_monthly_cost + local.volume_monthly_cost
  
  # Legacy cost variables for backward compatibility
  hourly_cost  = local.total_hourly_cost
  monthly_cost = local.total_monthly_cost
  
  # GPU Efficiency Analysis
  # Calculate efficiency rankings for all available GPUs in the current region
  available_gpu_specs = {
    for gpu_size in lookup(local.available_gpus, var.region, []) :
    gpu_size => local.gpu_specifications[gpu_size]
    if contains(keys(local.gpu_specifications), gpu_size)
  }
  
  # Efficiency rankings by different criteria
  efficiency_rankings = {
    # Best performance per dollar (FP16 TFLOPS per dollar per hour)
    performance_per_dollar = {
      for gpu_size, specs in local.available_gpu_specs :
      gpu_size => {
        metric = specs.tensor_fp16_per_dollar_hour
        rank = length([for k, v in local.available_gpu_specs : k if v.tensor_fp16_per_dollar_hour > specs.tensor_fp16_per_dollar_hour]) + 1
        description = "${format("%.1f", specs.tensor_fp16_per_dollar_hour)} TFLOPS per $/hour"
      }
    }
    
    # Best memory per dollar (GB per dollar per hour)
    memory_per_dollar = {
      for gpu_size, specs in local.available_gpu_specs :
      gpu_size => {
        metric = specs.memory_gb_per_dollar_hour
        rank = length([for k, v in local.available_gpu_specs : k if v.memory_gb_per_dollar_hour > specs.memory_gb_per_dollar_hour]) + 1
        description = "${format("%.1f", specs.memory_gb_per_dollar_hour)} GB per $/hour"
      }
    }
    
    # Most cost-effective (lowest hourly cost)
    lowest_cost = {
      for gpu_size, specs in local.available_gpu_specs :
      gpu_size => {
        metric = -specs.hourly  # Negative for reverse ranking (lower cost = better rank)
        rank = length([for k, v in local.available_gpu_specs : k if v.hourly < specs.hourly]) + 1
        description = "$${format("%.2f", specs.hourly)}/hour"
      }
    }
    
    # Highest absolute performance (total TFLOPS)
    absolute_performance = {
      for gpu_size, specs in local.available_gpu_specs :
      gpu_size => {
        metric = specs.tensor_performance_fp16
        rank = length([for k, v in local.available_gpu_specs : k if v.tensor_performance_fp16 > specs.tensor_performance_fp16]) + 1
        description = "${format("%.0f", specs.tensor_performance_fp16)} TFLOPS"
      }
    }
  }
  
  # Generate recommendations based on use cases
  gpu_recommendations = {
    development = {
      description = "Best for development, prototyping, and small models"
      recommended_gpus = [
        for gpu_size, specs in local.available_gpu_specs :
        {
          gpu_size = gpu_size
          model = specs.gpu_model
          hourly_cost = specs.hourly
          memory_gb = specs.gpu_memory_gb
          performance_tflops = specs.tensor_performance_fp16
          efficiency_score = specs.tensor_fp16_per_dollar_hour
          reason = "Low cost with adequate performance for development work"
        }
        if specs.hourly < 2.0  # Under $2/hour
      ]
    }
    
    training = {
      description = "Best for model training workloads"
      recommended_gpus = [
        for gpu_size, specs in local.available_gpu_specs :
        {
          gpu_size = gpu_size
          model = specs.gpu_model
          hourly_cost = specs.hourly
          memory_gb = specs.gpu_memory_gb
          performance_tflops = specs.tensor_performance_fp16
          efficiency_score = specs.tensor_fp16_per_dollar_hour
          reason = "High performance-to-cost ratio for training"
        }
        if specs.tensor_fp16_per_dollar_hour > 300  # Good efficiency threshold
      ]
    }
    
    inference = {
      description = "Best for high-performance inference workloads"
      recommended_gpus = [
        for gpu_size, specs in local.available_gpu_specs :
        {
          gpu_size = gpu_size
          model = specs.gpu_model
          hourly_cost = specs.hourly
          memory_gb = specs.gpu_memory_gb
          performance_tflops = specs.tensor_performance_fp16
          efficiency_score = specs.tensor_fp16_per_dollar_hour
          reason = "Balanced performance and memory for inference"
        }
        if specs.gpu_memory_gb >= 48  # Adequate memory for inference
      ]
    }
    
    large_models = {
      description = "Best for large language models and memory-intensive workloads"
      recommended_gpus = [
        for gpu_size, specs in local.available_gpu_specs :
        {
          gpu_size = gpu_size
          model = specs.gpu_model
          hourly_cost = specs.hourly
          memory_gb = specs.gpu_memory_gb
          performance_tflops = specs.tensor_performance_fp16
          efficiency_score = specs.memory_gb_per_dollar_hour
          reason = "High memory capacity for large models"
        }
        if specs.gpu_memory_gb >= 80  # High memory requirement
      ]
    }
  }
  
  # SSH key management - determine which keys to use
  final_ssh_key_ids = length(var.ssh_key_ids) > 0 ? var.ssh_key_ids : (
    var.auto_import_ssh_keys ? (
      length(var.ssh_key_names) > 0 ? 
        [for key in data.digitalocean_ssh_key.named_keys : key.id] :
        try(data.digitalocean_ssh_keys.account_keys[0].ssh_keys[*].id, [])
    ) : []
  )
  
  # Generate a unique name with timestamp if requested
  droplet_name = var.use_timestamp ? "${var.name}-${formatdate("YYYYMMDD-hhmmss", timestamp())}" : var.name
  
  # Prepare LocalAI installation script if enabled
  localai_install_script = var.install_localai ? templatefile(
    "${path.module}/templates/localai_install.sh",
    {
      localai_port        = var.localai_port
      localai_threads     = var.localai_threads
      localai_context_size = var.localai_context_size
      localai_models      = join("\n", [for m in var.localai_models : "wget -O /opt/localai/LocalAI/models/${split("=", m)[0]} ${split("=", m)[1]}"])
    }
  ) : ""
  
  # Prepare Ollama installation script if enabled
  ollama_install_script = var.install_ollama ? templatefile(
    "${path.module}/templates/ollama_install.sh",
    {
      ollama_model        = var.ollama_model
      ollama_port         = var.ollama_port
      install_ollama_webui = var.install_ollama_webui
    }
  ) : ""
  
  # Volume mounting script (runs first if volume is enabled)
  volume_mount_script = var.volume_size_gb > 0 ? templatefile("${path.module}/templates/volume_mount.sh", {
    volume_filesystem = var.volume_filesystem
  }) : ""
  
  # Combine all user data scripts in proper order
  combined_user_data = join("\n\n", compact([
    var.user_data,
    var.volume_size_gb > 0 ? local.volume_mount_script : "",
    var.install_localai ? local.localai_install_script : "",
    var.install_ollama ? local.ollama_install_script : ""
  ]))
}

# Data source to get available regions and their features
data "digitalocean_regions" "available" {
  filter {
    key    = "available"
    values = ["true"]
  }
  
  filter {
    key    = "features"
    values = ["private_networking", "backups", "ipv6", "monitoring", "storage"]
  }
}

# Data source to get all SSH keys from the DigitalOcean account
data "digitalocean_ssh_keys" "account_keys" {
  count = var.auto_import_ssh_keys && length(var.ssh_key_ids) == 0 ? 1 : 0
}

# Data source to get specific SSH keys by name
data "digitalocean_ssh_key" "named_keys" {
  count = var.auto_import_ssh_keys && length(var.ssh_key_names) > 0 ? length(var.ssh_key_names) : 0
  name  = var.ssh_key_names[count.index]
}

# Create the GPU droplet
resource "digitalocean_droplet" "gpu" {
  count = var.enabled && local.valid_gpu_size != null ? 1 : 0
  
  image    = var.image
  name     = local.droplet_name
  region   = var.region
  size     = local.valid_gpu_size
  ssh_keys = local.final_ssh_key_ids
  
  # Features
  monitoring = var.enable_monitoring
  backups    = var.enable_backups
  ipv6       = var.enable_ipv6
  
  # Networking
  vpc_uuid = var.vpc_uuid != "" ? var.vpc_uuid : null
  
  # Storage
  volume_ids = digitalocean_volume.gpu_volume[*].id
  
  # Tags
  tags = concat(
    ["gpu-droplet", "region:${var.region}", "size:${local.valid_gpu_size}"],
    var.tags
  )
  
  # User data for initial setup
  user_data = local.combined_user_data
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags and user_data after creation
      tags,
      user_data,
      # Allow the droplet to be recreated if the image changes
      image
    ]
  }
}

# Create and attach a volume if requested
resource "digitalocean_volume" "gpu_volume" {
  count = var.enabled && var.volume_size_gb > 0 ? 1 : 0
  
  region                   = var.region
  name                     = "${var.name}-volume"
  size                     = var.volume_size_gb
  initial_filesystem_type  = var.volume_filesystem
  description              = "Additional storage for GPU droplet ${var.name} - AI model storage"
  
  tags = concat(
    ["gpu-volume", "attached-to:${local.droplet_name}", "ai-models", "protected"],
    var.tags
  )
  
  # Lifecycle management for AI model protection
  lifecycle {
    # Protect volume from accidental destruction unless explicitly allowed
    prevent_destroy = var.protect_volume && !var.allow_volume_destruction
    
    # Ignore changes to tags after creation to prevent unnecessary updates
    ignore_changes = [tags]
  }
}

# Volume snapshot creation before volume destruction (if enabled)
resource "null_resource" "volume_snapshot" {
  count = var.enabled && var.volume_size_gb > 0 && var.create_volume_snapshot_on_destroy ? 1 : 0
  
  # Trigger snapshot creation when volume is about to be destroyed
  triggers = {
    volume_id = digitalocean_volume.gpu_volume[0].id
    volume_name = digitalocean_volume.gpu_volume[0].name
    snapshot_name = var.volume_snapshot_name != "" ? var.volume_snapshot_name : "${var.name}-volume-snapshot-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  }
  
  # Create volume snapshot before destroying volume
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Creating snapshot of volume ${self.triggers.volume_id} before destruction..."
      
      # Check if doctl is available
      if ! command -v doctl &> /dev/null; then
        echo "ERROR: doctl CLI is not installed. Please install doctl to enable volume snapshot functionality."
        echo "Installation: https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
      fi
      
      # Check if doctl is authenticated
      if ! doctl account get &> /dev/null; then
        echo "ERROR: doctl is not authenticated. Please run 'doctl auth init' first."
        exit 1
      fi
      
      # Create the volume snapshot
      echo "Creating volume snapshot: ${self.triggers.snapshot_name}"
      snapshot_result=$(doctl compute volume-action snapshot ${self.triggers.volume_id} --snapshot-name "${self.triggers.snapshot_name}" --format ID --no-header 2>&1)
      
      if [ $? -eq 0 ]; then
        action_id=$(echo "$snapshot_result" | tr -d '\n')
        echo "Volume snapshot creation initiated. Action ID: $action_id"
        echo "Waiting for volume snapshot to complete..."
        
        # Wait for snapshot to complete (with timeout)
        timeout=1800  # 30 minutes timeout
        elapsed=0
        interval=30
        
        while [ $elapsed -lt $timeout ]; do
          status=$(doctl compute action get $action_id --format Status --no-header 2>/dev/null || echo "error")
          
          if [ "$status" = "completed" ]; then
            echo "✅ Volume snapshot created successfully: ${self.triggers.snapshot_name}"
            
            # Get snapshot details
            snapshot_info=$(doctl compute volume-snapshot list --format "Name,ID,Size" --no-header | grep "${self.triggers.snapshot_name}" || echo "Volume snapshot details not found")
            echo "Volume snapshot details: $snapshot_info"
            
            # Log snapshot information
            mkdir -p "${path.root}/volume-snapshots"
            cat > "${path.root}/volume-snapshots/${self.triggers.snapshot_name}.json" << EOF
{
  "snapshot_name": "${self.triggers.snapshot_name}",
  "volume_id": "${self.triggers.volume_id}",
  "volume_name": "${self.triggers.volume_name}",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "action_id": "$action_id",
  "status": "completed",
  "details": "$snapshot_info",
  "type": "volume_snapshot"
}
EOF
            echo "Volume snapshot log saved to: ${path.root}/volume-snapshots/${self.triggers.snapshot_name}.json"
            break
          elif [ "$status" = "errored" ]; then
            echo "❌ Volume snapshot creation failed with error status"
            exit 1
          else
            echo "Volume snapshot in progress... Status: $status (${elapsed}s elapsed)"
            sleep $interval
            elapsed=$((elapsed + interval))
          fi
        done
        
        if [ $elapsed -ge $timeout ]; then
          echo "⚠️  Volume snapshot creation timed out after ${timeout}s. Check DigitalOcean dashboard for status."
          echo "Action ID: $action_id"
        fi
      else
        echo "❌ Failed to create volume snapshot: $snapshot_result"
        exit 1
      fi
    EOT
  }
  
  depends_on = [digitalocean_volume.gpu_volume]
}

# Create floating IP if requested
resource "digitalocean_floating_ip" "gpu_ip" {
  count  = var.enabled && var.enable_floating_ip && local.valid_gpu_size != null ? 1 : 0
  region = var.region
  
  # Note: The DigitalOcean provider doesn't support tags on floating IPs
  # as of the current version
  
  depends_on = [digitalocean_droplet.gpu]
}

# Snapshot creation before droplet destruction
resource "null_resource" "droplet_snapshot" {
  count = var.enabled && var.create_snapshot_on_destroy && local.valid_gpu_size != null ? 1 : 0
  
  # Trigger snapshot creation when droplet is about to be destroyed
  triggers = {
    droplet_id = digitalocean_droplet.gpu[0].id
    snapshot_name = var.snapshot_name != "" ? var.snapshot_name : "${local.droplet_name}-snapshot-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  }
  
  # Create snapshot before destroying droplet
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Creating snapshot of droplet ${self.triggers.droplet_id} before destruction..."
      
      # Check if doctl is available
      if ! command -v doctl &> /dev/null; then
        echo "ERROR: doctl CLI is not installed. Please install doctl to enable snapshot functionality."
        echo "Installation: https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
      fi
      
      # Check if doctl is authenticated
      if ! doctl account get &> /dev/null; then
        echo "ERROR: doctl is not authenticated. Please run 'doctl auth init' first."
        exit 1
      fi
      
      # Create the snapshot
      echo "Creating snapshot: ${self.triggers.snapshot_name}"
      snapshot_result=$(doctl compute droplet-action snapshot ${self.triggers.droplet_id} --snapshot-name "${self.triggers.snapshot_name}" --format ID --no-header 2>&1)
      
      if [ $? -eq 0 ]; then
        action_id=$(echo "$snapshot_result" | tr -d '\n')
        echo "Snapshot creation initiated. Action ID: $action_id"
        echo "Waiting for snapshot to complete..."
        
        # Wait for snapshot to complete (with timeout)
        timeout=1800  # 30 minutes timeout
        elapsed=0
        interval=30
        
        while [ $elapsed -lt $timeout ]; do
          status=$(doctl compute action get $action_id --format Status --no-header 2>/dev/null || echo "error")
          
          if [ "$status" = "completed" ]; then
            echo "✅ Snapshot created successfully: ${self.triggers.snapshot_name}"
            
            # Get snapshot details
            snapshot_info=$(doctl compute snapshot list --format "Name,ID,Size" --no-header | grep "${self.triggers.snapshot_name}" || echo "Snapshot details not found")
            echo "Snapshot details: $snapshot_info"
            
            # Log snapshot information
            mkdir -p "${path.root}/snapshots"
            cat > "${path.root}/snapshots/${self.triggers.snapshot_name}.json" << EOF
{
  "snapshot_name": "${self.triggers.snapshot_name}",
  "droplet_id": "${self.triggers.droplet_id}",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "action_id": "$action_id",
  "status": "completed",
  "details": "$snapshot_info"
}
EOF
            echo "Snapshot log saved to: ${path.root}/snapshots/${self.triggers.snapshot_name}.json"
            break
          elif [ "$status" = "errored" ]; then
            echo "❌ Snapshot creation failed with error status"
            exit 1
          else
            echo "Snapshot in progress... Status: $status (${elapsed}s elapsed)"
            sleep $interval
            elapsed=$((elapsed + interval))
          fi
        done
        
        if [ $elapsed -ge $timeout ]; then
          echo "⚠️  Snapshot creation timed out after ${timeout}s. Check DigitalOcean dashboard for status."
          echo "Action ID: $action_id"
        fi
      else
        echo "❌ Failed to create snapshot: $snapshot_result"
        exit 1
      fi
    EOT
  }
  
  depends_on = [digitalocean_droplet.gpu]
}

# Assign floating IP to droplet
resource "digitalocean_floating_ip_assignment" "gpu_ip_assignment" {
  count      = var.enabled && var.enable_floating_ip && local.valid_gpu_size != null ? 1 : 0
  ip_address = digitalocean_floating_ip.gpu_ip[0].ip_address
  droplet_id = digitalocean_droplet.gpu[0].id
  
  depends_on = [digitalocean_floating_ip.gpu_ip, digitalocean_droplet.gpu]
}

# Create firewall if requested
resource "digitalocean_firewall" "gpu_firewall" {
  count = var.enabled && var.enable_firewall && local.valid_gpu_size != null ? 1 : 0
  name  = "${local.droplet_name}-firewall"
  
  droplet_ids = [digitalocean_droplet.gpu[0].id]
  
  # Allow SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_cidrs
  }
  
  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  # Add LocalAI port if enabled
  dynamic "inbound_rule" {
    for_each = var.install_localai ? [1] : []
    content {
      protocol         = "tcp"
      port_range       = tostring(var.localai_port)
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }
  
  # Add Ollama port if enabled
  dynamic "inbound_rule" {
    for_each = var.install_ollama ? [1] : []
    content {
      protocol         = "tcp"
      port_range       = tostring(var.ollama_port)
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }
  
  # Add Ollama Web UI port if enabled
  dynamic "inbound_rule" {
    for_each = (var.install_ollama && var.install_ollama_webui) ? [1] : []
    content {
      protocol         = "tcp"
      port_range       = "3000"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }
  
  # Add custom rules
  dynamic "inbound_rule" {
    for_each = var.additional_inbound_rules
    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range
      source_addresses = inbound_rule.value.source_addresses
    }
  }
  
  tags = ["gpu-firewall", "terraform-managed"]
}

# Create cost log directory
resource "null_resource" "create_cost_logs_dir" {
  count = var.enabled && var.enable_cost_tracking ? 1 : 0
  
  provisioner "local-exec" {
    command = "mkdir -p ${path.root}/cost_logs"
  }
  
  triggers = {
    always_run = "${timestamp()}"
  }
}

# Create a cost log file
resource "local_file" "cost_log" {
  count = var.enabled && var.enable_cost_tracking && local.valid_gpu_size != null ? 1 : 0
  
  filename = "${path.root}/cost_logs/${local.droplet_name}_costs.json"
  content = jsonencode({
    timestamp       = timestamp()
    droplet_id      = digitalocean_droplet.gpu[0].id
    droplet_name    = local.droplet_name
    region          = var.region
    gpu_size        = local.valid_gpu_size
    status          = "provisioned"
    costs = {
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
    tags = concat(
      ["gpu-droplet", "region:${var.region}", "size:${local.valid_gpu_size}"],
      var.tags
    )
  })
  
  directory_permission = "0755"
  file_permission     = "0644"
  
  depends_on = [
    digitalocean_droplet.gpu,
    null_resource.create_cost_logs_dir
  ]
}

# Output snapshot information if enabled
resource "local_file" "snapshot_info" {
  count = var.enabled && var.create_snapshot_on_destroy && local.valid_gpu_size != null ? 1 : 0
  
  filename = "${path.root}/snapshots/README.md"
  content = <<-EOT
# Droplet Snapshots

This directory contains information about snapshots created when droplets are destroyed.

## Current Configuration
- **Snapshot on Destroy**: ${var.create_snapshot_on_destroy ? "Enabled" : "Disabled"}
- **Snapshot Name**: ${var.snapshot_name != "" ? var.snapshot_name : "Auto-generated with timestamp"}
- **Droplet**: ${local.droplet_name}

## Snapshot Management

### View Available Snapshots
```bash
doctl compute snapshot list
```

### Create Droplet from Snapshot
```bash
# Create new droplet from snapshot
doctl compute droplet create my-restored-droplet \
  --image <snapshot-id> \
  --size ${var.gpu_size} \
  --region ${var.region} \
  --ssh-keys <your-ssh-key-id>
```

### Delete Old Snapshots
```bash
# List snapshots to find ID
doctl compute snapshot list

# Delete specific snapshot
doctl compute snapshot delete <snapshot-id>
```

## Important Notes
- Snapshots incur storage costs ($0.05/GB/month)
- Snapshots preserve the entire droplet state including installed software
- GPU droplet snapshots can be large (20GB+ depending on usage)
- Consider cleaning up old snapshots to manage costs

## Automation
Snapshots are automatically created when:
1. `create_snapshot_on_destroy = true` is set
2. `terraform destroy` is run
3. `doctl` CLI is installed and authenticated

Snapshot creation logs are saved as JSON files in this directory.
EOT

  depends_on = [null_resource.droplet_snapshot]
}

# Data source to get the project by name
data "digitalocean_project" "target_project" {
  count = var.enabled && var.project_name != "" ? 1 : 0
  name  = var.project_name
}

# Assign the droplet to the specified project
resource "digitalocean_project_resources" "gpu_droplet_assignment" {
  count   = var.enabled && var.project_name != "" && local.valid_gpu_size != null ? 1 : 0
  project = data.digitalocean_project.target_project[0].id
  
  resources = compact([
    digitalocean_droplet.gpu[0].urn,
    var.enable_floating_ip ? digitalocean_floating_ip.gpu_ip[0].urn : null,
    var.volume_size_gb > 0 ? digitalocean_volume.gpu_volume[0].urn : null
  ])
  
  depends_on = [
    digitalocean_droplet.gpu,
    digitalocean_floating_ip.gpu_ip,
    digitalocean_volume.gpu_volume
  ]
}
