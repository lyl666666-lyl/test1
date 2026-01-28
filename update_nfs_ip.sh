#!/bin/bash

# 快速更新 NFS IP 配置脚本
# 当你切换网络后运行此脚本

echo "==========================================="
echo "Update NFS IP Configuration"
echo "==========================================="

# 获取当前 IP
CURRENT_IP=$(hostname -I | awk '{print $1}')
echo "Current IP: $CURRENT_IP"

# 项目路径
PROJECT_DIR="/home/lyl/test/MyBuman"
LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"

# 检查 IP 是否在 10.0.x.x 网段
if [[ $CURRENT_IP == 10.0.* ]]; then
    echo "✓ You are in the robot network"
    
    # 更新 /etc/exports
    echo "Updating NFS exports..."
    sudo sed -i '/Real_Logs/d' /etc/exports
    echo "$LOGS_DIR 10.0.0.0/8(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
    
    # 重启 NFS
    echo "Restarting NFS server..."
    sudo exportfs -ra
    sudo systemctl restart nfs-kernel-server
    
    echo ""
    echo "✓ NFS updated for IP: $CURRENT_IP"
    echo ""
    echo "Robots can now mount:"
    echo "  sudo mount -t nfs -o rw,soft,timeo=10 $CURRENT_IP:$LOGS_DIR /mnt/dev_logs"
    echo ""
else
    echo "⚠ Warning: You are not in the robot network (10.0.x.x)"
    echo "Current IP: $CURRENT_IP"
    echo ""
    echo "NFS is still configured, but robots may not be able to connect."
fi

echo ""
echo "Current NFS exports:"
sudo exportfs -v

echo ""
echo "==========================================="
echo "Done!"
echo "==========================================="
