#!/bin/bash
# Auto-upload logs to development machine after game ends
# This script runs on the robot

# Configuration - EDIT THESE VALUES
DEV_MACHINE_IP="10.0.1.100"  # Your development machine IP
DEV_MACHINE_USER="lyl"        # Your username on dev machine
DEV_MACHINE_PATH="/home/lyl/test/MyBuman/Config/Real_Logs"
SSH_KEY="/home/nao/.ssh/id_rsa"

# Log directory on robot
ROBOT_LOG_DIR="/home/nao/logs"

# Function to upload logs
upload_logs() {
    echo "[$(date)] Checking for logs to upload..."
    
    # Check if there are any log files
    if [ ! "$(ls -A $ROBOT_LOG_DIR)" ]; then
        echo "No logs to upload"
        return
    fi
    
    # Get robot name
    ROBOT_NAME=$(hostname)
    
    # Create timestamp for this upload
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    # Create remote directory
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        "$DEV_MACHINE_USER@$DEV_MACHINE_IP" \
        "mkdir -p $DEV_MACHINE_PATH/$TIMESTAMP/$ROBOT_NAME" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "Uploading logs to $DEV_MACHINE_IP:$DEV_MACHINE_PATH/$TIMESTAMP/$ROBOT_NAME/"
        
        # Upload all logs
        scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            -r $ROBOT_LOG_DIR/* \
            "$DEV_MACHINE_USER@$DEV_MACHINE_IP:$DEV_MACHINE_PATH/$TIMESTAMP/$ROBOT_NAME/" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "Upload successful! Cleaning up local logs..."
            rm -rf $ROBOT_LOG_DIR/*
            echo "Local logs cleaned"
        else
            echo "Upload failed, keeping local logs"
        fi
    else
        echo "Cannot connect to development machine, keeping local logs"
    fi
}

# Main logic
case "$1" in
    "upload")
        upload_logs
        ;;
    "auto")
        # Auto mode: upload when game state changes to finished
        # This would be called by the bhuman process
        upload_logs
        ;;
    *)
        echo "Usage: $0 {upload|auto}"
        echo "  upload - Upload logs immediately"
        echo "  auto   - Upload logs automatically (called by bhuman)"
        exit 1
        ;;
esac
