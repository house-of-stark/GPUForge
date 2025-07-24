# 🤖 GPUForge Model Intelligence - AI Models That Actually Fit!

🔥 **The GPUForge Model Promise: Perfect AI Models for Your GPU!** Our intelligent Model Intelligence system analyzes your GPU's VRAM, performance characteristics, and use case to recommend the perfect Ollama models that will run smoothly without memory issues, plus specialized recommendations for MCP tool integration.

## Overview

After creating a GPU droplet, the module automatically analyzes the GPU specifications and provides:

1. **VRAM-optimized model recommendations** - Models that fit within your GPU's memory
2. **MCP Tool-aware suggestions** - Models optimized for function calling and structured output
3. **Performance optimization guidance** - Quantization and configuration recommendations
4. **Quick start commands** - Ready-to-use setup instructions

## GPU VRAM Categories and Model Recommendations

### 🚀 High-End GPUs (80GB+ VRAM)
**GPU Models**: H100 (80GB), A100 (80GB)

#### General Purpose Models
- **llama3.1:70b** - Large-scale reasoning, production workloads
- **codellama:70b** - Advanced code generation and analysis  
- **mixtral:8x22b** - Multi-domain expertise with MoE architecture

#### MCP Tool Models
- **llama3.1:70b** - Excellent function calling and structured output
- **codellama:70b** - Superior code analysis with tool integration

### 💪 Mid-Range GPUs (40-79GB VRAM)
**GPU Models**: RTX 6000 Ada (48GB), A40 (48GB)

#### General Purpose Models
- **llama3.1:33b** - High-quality reasoning, balanced performance
- **codellama:34b** - Professional code generation
- **mixtral:8x7b** - Efficient multi-domain model

#### MCP Tool Models
- **llama3.1:33b** - Excellent function calling capabilities
- **codellama:34b** - Strong code analysis with tool integration

### ⚡ Standard GPUs (20-39GB VRAM)
**GPU Models**: RTX 4000 Ada (20GB), RTX A5000 (24GB)

#### General Purpose Models
- **llama3.1:13b** - Good general purpose, fast inference
- **codellama:13b** - Code generation and debugging
- **llama3.1:8b** - Fast inference for development

#### MCP Tool Models
- **llama3.1:13b** - Good function calling and tool usage
- **llama3.1:8b** - Basic tool usage, fast inference

### 🔧 Entry-Level GPUs (<20GB VRAM)
**GPU Models**: RTX 4000x1 (20GB), smaller configurations

#### General Purpose Models
- **llama3.1:8b** - Efficient for smaller GPUs
- **phi3:14b** - Microsoft's efficient model
- **gemma2:9b** - Google's optimized model

#### MCP Tool Models
- **llama3.1:8b** - Basic MCP tool integration

## MCP Tool-Aware Model Features

### Function Calling Capabilities
Models are rated on their ability to:
- **Parse function schemas** - Understanding tool definitions
- **Generate structured calls** - Proper JSON formatting
- **Handle complex workflows** - Multi-step tool usage
- **Error recovery** - Graceful handling of tool failures

### Quality Ratings

#### Excellent (70B+ models)
- Native function calling support
- Complex multi-tool workflows
- Reliable structured output
- Advanced error handling

#### Very Good (30B+ models)  
- Reliable function calling
- Good structured output
- Handles most tool scenarios
- Decent error recovery

#### Good (13B models)
- Basic function calling
- Adequate structured output
- Simple tool workflows
- Limited error handling

#### Fair (8B models)
- Basic tool usage
- Simple JSON generation
- Single-tool scenarios
- Minimal error handling

## Specialized Models

### Embedding Models
```bash
# Essential for RAG and semantic search
ollama pull nomic-embed-text
# Size: 137M parameters, ~1GB VRAM
```

### Vision Models
```bash
# For image analysis and vision-language tasks
ollama pull llava:13b    # 20GB+ VRAM recommended
ollama pull llava:7b     # For smaller GPUs
```

### Mathematical Models
```bash
# For mathematical reasoning and problem solving
ollama pull deepseek-math:7b
```

## Quantization Guide

### Q4_0 - Maximum Efficiency
- **Use case**: Development, testing, resource-constrained environments
- **Quality**: Lowest, but fastest inference
- **VRAM**: Minimal usage

### Q4_K_M - Recommended Balance ⭐
- **Use case**: Most production workloads
- **Quality**: Good balance of speed and accuracy
- **VRAM**: Moderate usage

### Q5_K_M - Higher Quality
- **Use case**: Production workloads requiring better quality
- **Quality**: Higher accuracy, slightly slower
- **VRAM**: Increased usage

### Q6_K - Near-Original Quality
- **Use case**: Quality-critical applications
- **Quality**: Very high, slower inference
- **VRAM**: High usage

### Q8_0 - Maximum Quality
- **Use case**: When quality is paramount and VRAM allows
- **Quality**: Highest, slowest inference
- **VRAM**: Maximum usage

## Usage Examples

### Accessing Recommendations
```bash
# View all model recommendations
terraform output ollama_model_recommendations

# View MCP-specific recommendations
terraform output mcp_tool_model_recommendations

# Get quick start guide
terraform output ollama_quick_start
```

### Quick Start Workflow
```bash
# 1. Connect to your droplet
ssh -i ~/.ssh/id_rsa root@YOUR_DROPLET_IP

# 2. Check GPU status
nvidia-smi

# 3. Pull recommended model (example for 40GB+ GPU)
ollama pull llama3.1:33b

# 4. Test the model
ollama run llama3.1:33b "Hello! Can you help me with coding tasks?"

# 5. For MCP integration, also pull embedding model
ollama pull nomic-embed-text
```

### MCP Integration Setup
```bash
# Pull MCP-optimized model
ollama pull llama3.1:33b

# Configure for function calling (example system prompt)
ollama run llama3.1:33b
>>> /set system "You are an AI assistant with access to tools. When using tools, always format your responses as valid JSON. Be precise with function calls and handle errors gracefully."

# Test function calling capability
>>> "Can you help me analyze this code using available tools?"
```

## Performance Optimization

### Concurrent Model Usage

#### High-End GPUs (80GB+)
```bash
# Can run multiple models simultaneously
ollama serve &
ollama pull llama3.1:33b
ollama pull nomic-embed-text  
ollama pull llava:13b

# Use different models for different tasks
curl -X POST http://localhost:11434/api/generate \
  -d '{"model": "llama3.1:33b", "prompt": "Code analysis task"}'

curl -X POST http://localhost:11434/api/embeddings \
  -d '{"model": "nomic-embed-text", "prompt": "Text for embedding"}'
```

#### Mid-Range GPUs (40-79GB)
```bash
# Run main model + embedding model
ollama pull llama3.1:13b
ollama pull nomic-embed-text
```

#### Standard GPUs (20-39GB)
```bash
# One model at a time for optimal performance
ollama pull llama3.1:13b
```

### Batch Processing
```bash
# For high-end GPUs - use larger batch sizes
curl -X POST http://localhost:11434/api/generate \
  -d '{"model": "llama3.1:33b", "prompt": "Batch task", "options": {"batch_size": 32}}'

# For standard GPUs - moderate batch sizes
curl -X POST http://localhost:11434/api/generate \
  -d '{"model": "llama3.1:13b", "prompt": "Task", "options": {"batch_size": 8}}'
```

## MCP Workflow Examples

### Development Workflow
```bash
# Use CodeLlama for code analysis
ollama pull codellama:34b

# Example MCP tool integration
curl -X POST http://localhost:11434/api/generate \
  -d '{
    "model": "codellama:34b",
    "prompt": "Analyze this Python function and suggest improvements using code analysis tools",
    "system": "You have access to code analysis tools. Use them to provide detailed feedback."
  }'
```

### Data Analysis Workflow
```bash
# Combine Llama3.1 with embeddings for RAG
ollama pull llama3.1:33b
ollama pull nomic-embed-text

# Use for document analysis with MCP tools
curl -X POST http://localhost:11434/api/generate \
  -d '{
    "model": "llama3.1:33b", 
    "prompt": "Analyze these documents using available search and analysis tools",
    "system": "You can use document search, embedding, and analysis tools to provide comprehensive insights."
  }'
```

### Automation Workflow
```bash
# Use function calling for automated tasks
ollama pull llama3.1:33b

# Example automated workflow
curl -X POST http://localhost:11434/api/generate \
  -d '{
    "model": "llama3.1:33b",
    "prompt": "Execute this automation workflow using available tools",
    "system": "You have access to automation tools. Execute tasks step by step and handle any errors."
  }'
```

## Monitoring and Management

### GPU Monitoring
```bash
# Check GPU memory usage
nvidia-smi --query-gpu=memory.used,memory.total --format=csv

# Monitor GPU utilization
watch -n 1 nvidia-smi

# Check specific model memory usage
ollama show MODEL_NAME
```

### Model Management
```bash
# List installed models
ollama list

# Remove unused models to free space
ollama rm old-model-name

# Check model information
ollama show llama3.1:33b

# Check disk usage for model storage
df -h /mnt/ai-models/ollama/
```

### Ollama Service Management
```bash
# Check Ollama status
systemctl status ollama

# View Ollama logs
journalctl -u ollama -f

# Restart Ollama service
systemctl restart ollama
```

## Troubleshooting

### Out of Memory Errors
```bash
# Check available VRAM
nvidia-smi

# Try smaller model or different quantization
ollama pull llama3.1:8b  # Instead of larger model

# Clear model cache
ollama rm $(ollama list -q)
```

### Model Loading Issues
```bash
# Check model file integrity
ollama show MODEL_NAME

# Re-download corrupted model
ollama rm MODEL_NAME
ollama pull MODEL_NAME

# Check disk space
df -h /mnt/ai-models/
```

### Performance Issues
```bash
# Check GPU utilization
nvidia-smi

# Verify model is using GPU
ollama run MODEL_NAME "test" --verbose

# Check for thermal throttling
nvidia-smi -q -d TEMPERATURE
```

### MCP Integration Issues
```bash
# Test function calling capability
ollama run llama3.1:33b
>>> "Please respond with a JSON object containing your capabilities"

# Verify structured output
curl -X POST http://localhost:11434/api/generate \
  -d '{"model": "llama3.1:33b", "prompt": "Return a JSON object with status and message fields"}'
```

## Cost Optimization

### Model Selection Strategy
- **Development**: Use smaller models (8B-13B) for testing and development
- **Production**: Scale up to larger models (33B-70B) based on requirements
- **MCP Workflows**: Balance model size with function calling quality needs

### Storage Management
```bash
# Monitor model storage usage
du -sh /mnt/ai-models/ollama/models/*

# Remove unused quantizations
ollama rm model:q8_0  # Keep only needed quantizations

# Use volume snapshots before major changes
# (Handled automatically by the Terraform module)
```

### GPU Utilization
- **High-end GPUs**: Maximize utilization with larger models or concurrent models
- **Mid-range GPUs**: Balance between model size and response time
- **Entry-level GPUs**: Focus on efficiency with smaller, optimized models

## Integration with Other Services

### LocalAI Compatibility
The droplet also includes LocalAI installation. You can:
- Use Ollama for chat and completion tasks
- Use LocalAI for OpenAI-compatible API endpoints
- Share models between services via the mounted volume

### API Access
```bash
# Ollama API (native)
curl http://YOUR_DROPLET_IP:11434/api/generate

# LocalAI API (OpenAI-compatible)
curl http://YOUR_DROPLET_IP:8080/v1/chat/completions
```

## 🏆 Pro Forge Strategies from the Community

💡 **Master the art of AI model forging!** These battle-tested strategies from the GPUForge community have helped users maximize their GPU potential:

This comprehensive model recommendation system ensures you get the most out of your GPU investment with optimized model selection for both general use and specialized MCP Tool integration! 🚀🤖
