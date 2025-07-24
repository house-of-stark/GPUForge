#!/bin/bash
set -e

# Update and install prerequisites
apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    cmake \
    wget \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    nvidia-cuda-toolkit \
    nvidia-driver-535 \
    ocl-icd-opencl-dev \
    ocl-icd-libopencl1 \
    opencl-headers \
    clinfo \
    libclblast-dev \
    libssl-dev

# Install Go
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install LocalAI
mkdir -p /opt/localai
cd /opt/localai

git clone --depth=1 https://github.com/go-skynet/LocalAI
cd LocalAI

# Install Python dependencies
python3 -m venv venv
source venv/bin/activate
pip install -f https://download.pytorch.org/whl/nightly/cu121/torch_nightly.html \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu121
pip install -r requirements.txt

# Build LocalAI
make build

# Create systemd service with volume-based model storage
cat > /etc/systemd/system/localai.service <<EOL
[Unit]
Description=LocalAI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/localai
# Use mounted volume for model storage
ExecStart=/opt/localai/local-ai --models-path=/mnt/ai-models/localai/models --address=0.0.0.0:8080
Restart=always
RestartSec=3
# Environment variables for model storage
Environment="LOCALAI_MODELS_PATH=/mnt/ai-models/localai/models"

[Install]
WantedBy=multi-user.target
EOL

# Build LocalAI with GPU support
cd /opt/localai
make BUILD_TYPE=cublas

# Set up model storage on mounted volume
echo "Setting up LocalAI model storage on mounted volume..."
mkdir -p /mnt/ai-models/localai/models
chown -R root:root /mnt/ai-models/localai

# Create symlink for LocalAI models directory
ln -sf /mnt/ai-models/localai/models /opt/localai/models
echo "LocalAI models will be stored in: /mnt/ai-models/localai/models"

# Download a small model for testing
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf

# Enable and start LocalAI service
systemctl daemon-reload
systemctl enable localai
systemctl start localai

# Create model management script
cat > /root/manage_localai_models.sh <<'EOF'
#!/bin/bash
echo "=== LocalAI Model Management ==="
echo "Model storage location: /mnt/ai-models/localai/models"
echo "Available space: $(df -h /mnt/ai-models | tail -1 | awk '{print $4}')"
echo ""
echo "Installed models:"
ls -lah /mnt/ai-models/localai/models/ 2>/dev/null || echo "No model files found"
echo ""
echo "LocalAI service status:"
systemctl status localai --no-pager -l
echo ""
echo "To download models, place them in: /mnt/ai-models/localai/models/"
echo "To restart LocalAI: systemctl restart localai"
EOF
chmod +x /root/manage_localai_models.sh

# Create a test script with volume information
cat > /root/test_localai.py <<EOL
import openai

client = openai.OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="no-api-key-required"
)

response = client.chat.completions.create(
    model="tinyllama-1.1b-chat-v1.0.Q4_K_M",
    messages=[
        {"role": "system", "content": "You are a helpful AI assistant."},
        {"role": "user", "content": "What is LocalAI?"}
    ]
)

print(response.choices[0].message.content)
EOL

echo "LocalAI installation completed successfully!"
echo "Models will be stored in: /mnt/ai-models/localai/models"
echo "Use /root/manage_localai_models.sh to manage models"
echo "To test the installation, run: python3 /root/test_localai.py"
echo "LocalAI web interface will be available at: http://$(curl -s ifconfig.me):8080"
echo "Model storage usage: $(df -h /mnt/ai-models | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
