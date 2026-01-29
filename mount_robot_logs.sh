#!/bin/bash

# NAO 机器人日志挂载脚本
# 使用方法: ./mount_robot_logs.sh <机器人IP>
# 例如: ./mount_robot_logs.sh 10.0.70.13

ROBOT_PASSWORD="nao"
MOUNT_DIR="./mount_logs"
ROBOT_LOGS_DIR="/home/nao/logs"

# 检查参数
if [ -z "$1" ]; then
    echo "用法: $0 <机器人IP>"
    echo "例如: $0 10.0.70.15"
    echo ""
    echo "或者挂载所有配置的机器人:"
    echo "$0 all"
    exit 1
fi

# 创建挂载目录
mkdir -p "$MOUNT_DIR"

# 挂载单个机器人
mount_robot() {
    local robot_ip="$1"
    local robot_num=$(echo $robot_ip | awk -F. '{print $4}')
    local mount_point="$MOUNT_DIR/robot${robot_num}"
    
    echo "挂载机器人 #$robot_num ($robot_ip)..."
    
    # 检查机器人是否在线
    if ! ping -c 1 -W 1 $robot_ip > /dev/null 2>&1; then
        echo "  ✗ 机器人离线"
        return 1
    fi
    
    # 创建挂载点
    mkdir -p "$mount_point"
    
    # 检查是否已经挂载
    if mountpoint -q "$mount_point" 2>/dev/null; then
        echo "  ⚠️  已经挂载，先卸载..."
        fusermount -u "$mount_point" 2>/dev/null || umount "$mount_point" 2>/dev/null
    fi
    
    # 使用 sshfs 挂载（通过 sshpass）
    echo "  尝试挂载..."
    sshpass -p "$ROBOT_PASSWORD" sshfs nao@$robot_ip:$ROBOT_LOGS_DIR "$mount_point" \
        -o StrictHostKeyChecking=no \
        -o reconnect \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=3 \
        -o allow_other 2>&1
    
    result=$?
    
    # 如果 allow_other 失败，尝试不使用 allow_other
    if [ $result -ne 0 ]; then
        echo "  重试（不使用 allow_other）..."
        sshpass -p "$ROBOT_PASSWORD" sshfs nao@$robot_ip:$ROBOT_LOGS_DIR "$mount_point" \
            -o StrictHostKeyChecking=no \
            -o reconnect \
            -o ServerAliveInterval=15 \
            -o ServerAliveCountMax=3 2>&1
        result=$?
    fi
    
    if [ $result -eq 0 ]; then
        echo "  ✓ 挂载成功: $mount_point"
        echo "  访问: ls $mount_point"
        return 0
    else
        echo "  ✗ 挂载失败（错误码: $result）"
        return 1
    fi
}

# 卸载所有
unmount_all() {
    echo "卸载所有挂载点..."
    for mount_point in "$MOUNT_DIR"/robot*; do
        if [ -d "$mount_point" ] && mountpoint -q "$mount_point" 2>/dev/null; then
            echo "  卸载: $mount_point"
            fusermount -u "$mount_point" 2>/dev/null || umount "$mount_point" 2>/dev/null
        fi
    done
    echo "✓ 完成"
}

# 显示挂载状态
show_status() {
    echo "==========================================="
    echo "挂载状态"
    echo "==========================================="
    
    if [ ! -d "$MOUNT_DIR" ] || [ -z "$(ls -A $MOUNT_DIR 2>/dev/null)" ]; then
        echo "没有挂载点"
        return
    fi
    
    for mount_point in "$MOUNT_DIR"/robot*; do
        if [ -d "$mount_point" ]; then
            robot_num=$(basename "$mount_point" | sed 's/robot//')
            if mountpoint -q "$mount_point" 2>/dev/null; then
                file_count=$(ls -1 "$mount_point" 2>/dev/null | wc -l)
                echo "  ✓ robot$robot_num: 已挂载 ($file_count 个文件)"
            else
                echo "  ✗ robot$robot_num: 未挂载"
            fi
        fi
    done
}

# 主程序
case "$1" in
    "all")
        echo "==========================================="
        echo "挂载所有配置的机器人"
        echo "==========================================="
        echo ""
        
        # 从 extract_team_logs_simple.sh 读取配置
        TEAM_A_IPS=$(grep -A 10 "^TEAM_A=" extract_team_logs_simple.sh | grep -oP '\d+\.\d+\.\d+\.\d+' | sort -u)
        TEAM_B_IPS=$(grep -A 10 "^TEAM_B=" extract_team_logs_simple.sh | grep -oP '\d+\.\d+\.\d+\.\d+' | sort -u)
        
        ALL_IPS=$(echo -e "$TEAM_A_IPS\n$TEAM_B_IPS" | sort -u)
        
        for ip in $ALL_IPS; do
            mount_robot "$ip"
            echo ""
        done
        
        echo ""
        show_status
        ;;
        
    "unmount"|"umount")
        unmount_all
        ;;
        
    "status")
        show_status
        ;;
        
    *)
        mount_robot "$1"
        ;;
esac

echo ""
echo "提示:"
echo "  查看状态: $0 status"
echo "  卸载所有: $0 unmount"
