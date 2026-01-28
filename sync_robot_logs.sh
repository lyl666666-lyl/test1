#!/bin/bash

# 自动从机器人同步日志到本地
# 使用方法: ./sync_robot_logs.sh [机器人IP列表]
# 例如: ./sync_robot_logs.sh 10.0.70.6 10.0.70.7 10.0.70.11

PROJECT_DIR="/home/lyl/test/MyBuman"
LOCAL_LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"
ROBOT_LOGS_DIR="/home/nao/logs"

# 如果没有提供机器人 IP，使用默认列表
if [ $# -eq 0 ]; then
    echo "用法: $0 <机器人IP1> [机器人IP2] [机器人IP3] ..."
    echo "例如: $0 10.0.70.6 10.0.70.7 10.0.70.11"
    exit 1
fi

echo "==========================================="
echo "Robot Logs Sync"
echo "==========================================="
echo "本地日志目录: $LOCAL_LOGS_DIR"
echo ""

# 创建本地日志目录
mkdir -p "$LOCAL_LOGS_DIR"

# 遍历所有机器人
for ROBOT_IP in "$@"; do
    echo "-------------------------------------------"
    echo "同步机器人: $ROBOT_IP"
    echo "-------------------------------------------"
    
    # 提取机器人编号（IP 最后一位）
    ROBOT_NUM=$(echo $ROBOT_IP | awk -F. '{print $4}')
    ROBOT_DIR="$LOCAL_LOGS_DIR/robot_$ROBOT_NUM"
    
    # 创建机器人专属目录
    mkdir -p "$ROBOT_DIR"
    
    # 检查机器人是否在线
    if ping -c 1 -W 1 $ROBOT_IP > /dev/null 2>&1; then
        echo "✓ 机器人在线"
        
        # 同步日志文件
        echo "正在同步日志..."
        rsync -avz --progress \
            -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5" \
            nao@$ROBOT_IP:$ROBOT_LOGS_DIR/ \
            "$ROBOT_DIR/" 2>&1 | grep -v "^$"
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo "✓ 同步完成"
            echo "  日志位置: $ROBOT_DIR"
            
            # 显示最新的几个文件
            echo "  最新文件:"
            ls -lht "$ROBOT_DIR" | head -6 | tail -5 | awk '{print "    " $9 " (" $5 ")"}'
        else
            echo "✗ 同步失败"
        fi
    else
        echo "✗ 机器人离线或无法连接"
    fi
    echo ""
done

echo "==========================================="
echo "同步完成！"
echo "==========================================="
echo "所有日志保存在: $LOCAL_LOGS_DIR"
echo ""
echo "查看日志:"
echo "  ls -lh $LOCAL_LOGS_DIR/robot_*/"
