#!/bin/bash

# 持续监控并同步机器人日志
# 使用方法: ./watch_robot_logs.sh <机器人IP列表>
# 例如: ./watch_robot_logs.sh 10.0.70.6 10.0.70.7 10.0.70.11

if [ $# -eq 0 ]; then
    echo "用法: $0 <机器人IP1> [机器人IP2] [机器人IP3] ..."
    echo "例如: $0 10.0.70.6 10.0.70.7 10.0.70.11"
    echo ""
    echo "这个脚本会每 10 秒自动同步一次日志"
    echo "按 Ctrl+C 停止"
    exit 1
fi

INTERVAL=10  # 同步间隔（秒）

echo "==========================================="
echo "Robot Logs 持续监控"
echo "==========================================="
echo "同步间隔: ${INTERVAL}秒"
echo "机器人列表: $@"
echo "按 Ctrl+C 停止"
echo "==========================================="
echo ""

# 捕获 Ctrl+C
trap 'echo ""; echo "停止监控..."; exit 0' INT

COUNT=1
while true; do
    echo "[$(date +"%H:%M:%S")] 第 $COUNT 次同步"
    ./sync_robot_logs.sh "$@"
    
    echo "等待 ${INTERVAL} 秒..."
    echo ""
    sleep $INTERVAL
    COUNT=$((COUNT + 1))
done
