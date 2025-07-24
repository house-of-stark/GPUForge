#!/bin/bash
set -e

# Volume Mount and AI Model Storage Setup Script
# This script mounts the attached volume and configures it for AI model storage

echo "=== Setting up AI Model Storage Volume ==="

# Check if volume is attached
VOLUME_DEVICE=""
for device in /dev/disk/by-id/scsi-0DO_Volume_*; do
    if [ -e "$device" ]; then
        VOLUME_DEVICE="$device"
        break
    fi
done

if [ -z "$VOLUME_DEVICE" ]; then
    echo "No DigitalOcean volume found. Skipping volume setup."
    exit 0
fi

echo "Found volume device: $VOLUME_DEVICE"

# Get the actual device path
ACTUAL_DEVICE=$(readlink -f "$VOLUME_DEVICE")
echo "Actual device path: $ACTUAL_DEVICE"

# Create mount point
MOUNT_POINT="/mnt/ai-models"
mkdir -p "$MOUNT_POINT"

# Check if volume is already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "Volume already mounted at $MOUNT_POINT"
else
    # Check if the volume has a filesystem
    if ! blkid "$ACTUAL_DEVICE" > /dev/null 2>&1; then
        echo "Formatting volume with ${volume_filesystem} filesystem..."
        mkfs.${volume_filesystem} "$ACTUAL_DEVICE"
    else
        echo "Volume already has a filesystem"
    fi
    
    # Mount the volume
    echo "Mounting volume at $MOUNT_POINT..."
    mount "$ACTUAL_DEVICE" "$MOUNT_POINT"
    
    # Add to fstab for persistent mounting
    VOLUME_UUID=$(blkid -s UUID -o value "$ACTUAL_DEVICE")
    if [ -n "$VOLUME_UUID" ]; then
        # Remove any existing entry for this mount point
        sed -i "\|$MOUNT_POINT|d" /etc/fstab
        # Add new entry
        echo "UUID=$VOLUME_UUID $MOUNT_POINT ${volume_filesystem} defaults,nofail 0 2" >> /etc/fstab
        echo "Added volume to /etc/fstab for persistent mounting"
    fi
fi

# Create directories for AI models
echo "Creating AI model directories..."
mkdir -p "$MOUNT_POINT/ollama/models"
mkdir -p "$MOUNT_POINT/localai/models"
mkdir -p "$MOUNT_POINT/shared/models"

# Set proper permissions
chown -R root:root "$MOUNT_POINT"
chmod -R 755 "$MOUNT_POINT"

# Create symlinks for easy access
ln -sf "$MOUNT_POINT/ollama" /opt/ollama-models
ln -sf "$MOUNT_POINT/localai" /opt/localai-models
ln -sf "$MOUNT_POINT/shared" /opt/shared-models

echo "=== AI Model Storage Setup Complete ==="
echo "Mount point: $MOUNT_POINT"
echo "Ollama models: $MOUNT_POINT/ollama/models"
echo "LocalAI models: $MOUNT_POINT/localai/models"
echo "Shared models: $MOUNT_POINT/shared/models"
echo "Available space: $(df -h $MOUNT_POINT | tail -1 | awk '{print $4}')"
