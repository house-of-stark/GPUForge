#!/bin/bash
set -e

# Install prerequisites
apt-get update
apt-get install -y --no-install-recommends \
    wget \
    curl \
    gnupg \
    ca-certificates \
    nvidia-cuda-toolkit \
    nvidia-driver-535 \
    ocl-icd-opencl-dev \
    ocl-icd-libopencl1 \
    opencl-headers \
    clinfo \
    libclblast-dev \
    libssl-dev

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Create systemd service for Ollama with volume-based model storage
cat > /etc/systemd/system/ollama.service <<EOL
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
# Use mounted volume for model storage
Environment="OLLAMA_MODELS=/mnt/ai-models/ollama/models"
User=root
Group=root
Restart=always
RestartSec=3
Environment="PATH=$PATH"
# Model storage on mounted volume
Environment="OLLAMA_MODELS=/mnt/ai-models/ollama/models"
Environment="OLLAMA_ORIGINS=*"
Environment="OLLAMA_PORT=${ollama_port}"

[Install]
WantedBy=default.target
EOL

# Create Ollama user and directories
useradd -r -s /bin/false ollama
mkdir -p /usr/share/ollama/.ollama
chown -R ollama:ollama /usr/share/ollama

# Set permissions
chmod 755 /usr/local/bin/ollama
chown -R ollama:ollama /usr/local/bin/ollama

# Enable and start Ollama service
systemctl daemon-reload
systemctl enable ollama
systemctl start ollama

# Wait for service to start
sleep 5

# Set up Ollama model directory and download model
echo "Setting up Ollama model storage..."
export OLLAMA_MODELS="/mnt/ai-models/ollama/models"
mkdir -p "$OLLAMA_MODELS"
chown -R root:root "$OLLAMA_MODELS"

# Download the specified model
echo "Downloading Ollama model: ${ollama_model}..."
/usr/local/bin/ollama pull "${ollama_model}" || echo "Failed to pull model ${ollama_model}"

# Set the Ollama port from the variable or use default
OLLAMA_PORT=${ollama_port}
if [ -z "$OLLAMA_PORT" ]; then
    OLLAMA_PORT=11434
fi

# Create test script with volume information
cat > /root/test_ollama.sh <<'EOF'
#!/bin/bash
echo "=== Ollama API Test ==="
curl -s http://localhost:${ollama_port}/api/tags | jq .
echo ""
echo "=== Model Storage Info ==="
echo "Model directory: $OLLAMA_MODELS"
echo "Available models:"
ls -la "$OLLAMA_MODELS" 2>/dev/null || echo "No models found"
echo "Storage usage:"
df -h /mnt/ai-models
echo ""
echo "=== Testing model generation ==="
curl -s http://localhost:${ollama_port}/api/generate -d '{
  "model": "${ollama_model}",
  "prompt": "Hello, world!",
  "stream": false
}' | jq .
EOF

chmod +x /root/test_ollama.sh

# Install Ollama Web UI (optional)
if [ "${install_ollama_webui}" = "true" ]; then
    echo "Installing Ollama Web UI..."
    curl -fsSL https://ollama-webui.vercel.app/install.sh | bash
    
    # Create Web UI service
    cat > /etc/systemd/system/ollama-webui.service << 'EOL'
[Unit]
Description=Ollama Web UI
After=network.target ollama.service
Requires=ollama.service

[Service]
User=ollama
WorkingDirectory=/usr/share/ollama
Environment="PATH=/usr/local/bin"
ExecStart=/bin/bash -c 'cd /usr/share/ollama/ollama-webui && PORT=3000 OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS=* OLLAMA_PORT=$OLLAMA_PORT /usr/local/bin/ollama serve > /var/log/ollama-webui.log 2>&1'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

    # Enable and start Web UI
    systemctl daemon-reload
    systemctl enable ollama-webui
    systemctl start ollama-webui
    
    # Add Web UI info to test script
    echo -e "\n# Web UI is available at:
echo 'Ollama Web UI: http://$(curl -s ifconfig.me):3000'" >> /root/test_ollama.sh
fi

# Create model management script
cat > /root/manage_ollama_models.sh <<'EOF'
#!/bin/bash
echo "=== Ollama Model Management ==="
echo "Model storage location: /mnt/ai-models/ollama/models"
echo "Available space: $(df -h /mnt/ai-models | tail -1 | awk '{print $4}')"
echo ""
echo "Installed models:"
/usr/local/bin/ollama list
echo ""
echo "Model files on disk:"
ls -lah /mnt/ai-models/ollama/models/ 2>/dev/null || echo "No model files found"
echo ""
echo "To pull a new model: ollama pull <model-name>"
echo "To remove a model: ollama rm <model-name>"
EOF
chmod +x /root/manage_ollama_models.sh

echo "Ollama installation completed successfully!"
echo "Models will be stored in: /mnt/ai-models/ollama/models"
echo "Use /root/manage_ollama_models.sh to manage models"
echo "Run '/root/test_ollama.sh' to verify the installation"
