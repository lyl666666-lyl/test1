#!/bin/bash
# Setup script to enable automatic robot logging to development machine
# Run this on your DEVELOPMENT MACHINE

set -e

# Configuration
DEV_MACHINE_IP=$(hostname -I | awk '{print $1}')
DEV_MACHINE_USER=$(whoami)
PROJECT_DIR=$(cd "$(dirname "$0")" && pwd)
REAL_LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"
NFS_MOUNT_DIR="/mnt/dev_logs"

echo "========================================="
echo "Robot Logging Setup"
echo "========================================="
echo "Development Machine IP: $DEV_MACHINE_IP"
echo "Development Machine User: $DEV_MACHINE_USER"
echo "Project Directory: $PROJECT_DIR"
echo "Real Logs Directory: $REAL_LOGS_DIR"
echo ""

# Create Real_Logs directory
mkdir -p "$REAL_LOGS_DIR"
echo "✓ Created $REAL_LOGS_DIR"

# Function to setup NFS (Option 1 - Recommended)
setup_nfs() {
    echo ""
    echo "========================================="
    echo "Option 1: NFS Setup (Recommended)"
    echo "========================================="
    echo "This allows robots to write logs directly to your machine"
    echo ""
    
    # Check if NFS server is installed
    if ! command -v exportfs &> /dev/null; then
        echo "Installing NFS server..."
        sudo apt-get update
        sudo apt-get install -y nfs-kernel-server
    fi
    
    # Add NFS export
    echo "Configuring NFS export..."
    NFS_EXPORT="$REAL_LOGS_DIR 10.0.70.0/24(rw,sync,no_subtree_check,no_root_squash)"
    
    if ! grep -q "$REAL_LOGS_DIR" /etc/exports; then
        echo "$NFS_EXPORT" | sudo tee -a /etc/exports
        echo "✓ Added NFS export to /etc/exports"
    else
        echo "✓ NFS export already exists"
    fi
    
    # Restart NFS server
    sudo exportfs -ra
    sudo systemctl restart nfs-kernel-server
    echo "✓ NFS server restarted"
    
    echo ""
    echo "NFS Setup Complete!"
    echo "Robots can now mount: $DEV_MACHINE_IP:$REAL_LOGS_DIR"
}

# Function to setup SSH keys (Option 2 - Fallback)
setup_ssh() {
    echo ""
    echo "========================================="
    echo "Option 2: SSH Setup (Fallback)"
    echo "========================================="
    echo "This allows robots to upload logs via SSH"
    echo ""
    
    # Generate SSH key if not exists
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        echo "Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    echo "✓ SSH key ready: ~/.ssh/id_rsa.pub"
    echo ""
    echo "You need to copy this key to each robot:"
    echo "  ssh-copy-id nao@10.0.70.6"
    echo "  ssh-copy-id nao@10.0.70.7"
    echo "  etc..."
}

# Function to create robot mount script
create_robot_mount_script() {
    local ROBOT_IP=$1
    
    cat > "/tmp/mount_dev_logs_${ROBOT_IP}.sh" << EOF
#!/bin/bash
# Mount development machine logs directory
# Run this on robot: $ROBOT_IP

DEV_IP="$DEV_MACHINE_IP"
DEV_PATH="$REAL_LOGS_DIR"
MOUNT_POINT="$NFS_MOUNT_DIR"

# Create mount point
sudo mkdir -p \$MOUNT_POINT

# Check if already mounted
if mount | grep -q "\$MOUNT_POINT"; then
    echo "Already mounted"
    exit 0
fi

# Mount NFS
sudo mount -t nfs -o rw,soft,timeo=10 \$DEV_IP:\$DEV_PATH \$MOUNT_POINT

if [ \$? -eq 0 ]; then
    echo "✓ Mounted \$DEV_IP:\$DEV_PATH to \$MOUNT_POINT"
    
    # Add to fstab for auto-mount on boot
    if ! grep -q "\$MOUNT_POINT" /etc/fstab; then
        echo "\$DEV_IP:\$DEV_PATH \$MOUNT_POINT nfs rw,soft,timeo=10 0 0" | sudo tee -a /etc/fstab
        echo "✓ Added to /etc/fstab for auto-mount"
    fi
else
    echo "✗ Failed to mount NFS"
    exit 1
fi
EOF
    
    chmod +x "/tmp/mount_dev_logs_${ROBOT_IP}.sh"
    echo "Created mount script: /tmp/mount_dev_logs_${ROBOT_IP}.sh"
}

# Main menu
echo "Choose setup method:"
echo "1) NFS (Recommended - Direct write, real-time)"
echo "2) SSH (Fallback - Upload after game)"
echo "3) Both"
echo "4) Skip setup, just create directories"
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        setup_nfs
        ;;
    2)
        setup_ssh
        ;;
    3)
        setup_nfs
        setup_ssh
        ;;
    4)
        echo "Skipping setup"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "1. Recompile your code:"
echo "   cd Make/Linux && make Nao"
echo ""
echo "2. Deploy to robots:"
echo "   ./deploy -r 1 10.0.70.6 -nc -t 70 -s Default -m 70 -w SPL_A -v 100 -b"
echo ""

if [ "$choice" = "1" ] || [ "$choice" = "3" ]; then
    echo "3. On each robot, run the mount script:"
    echo "   (The script will be copied during deployment)"
    echo "   Or manually: ssh nao@10.0.70.6 'sudo mount -t nfs $DEV_MACHINE_IP:$REAL_LOGS_DIR /mnt/dev_logs'"
    echo ""
fi

echo "4. Start playing! Logs will appear in:"
echo "   $REAL_LOGS_DIR"
echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
