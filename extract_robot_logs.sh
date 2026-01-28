#!/bin/bash

# 提取机器人日志脚本
# 使用方法: ./extract_robot_logs.sh <机器人IP列表>
# 例如: ./extract_robot_logs.sh 10.0.70.11 10.0.70.6 10.0.70.7

PROJECT_DIR="/home/lyl/test/MyBuman"
LOCAL_LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"
ROBOT_LOGS_DIR="/home/nao/logs"

if [ $# -eq 0 ]; then
    echo "用法: $0 <机器人IP1> [机器人IP2] [机器人IP3] ..."
    echo "例如: $0 10.0.70.11"
    echo "      $0 10.0.70.6 10.0.70.7 10.0.70.11"
    exit 1
fi

# 生成时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SESSION_DIR="$LOCAL_LOGS_DIR/${TIMESTAMP}"

echo "==========================================="
echo "机器人日志提取"
echo "==========================================="
echo "时间戳: $TIMESTAMP"
echo "保存目录: $SESSION_DIR"
echo "机器人列表: $@"
echo "==========================================="
echo ""

# 创建会话目录
mkdir -p "$SESSION_DIR"

# 遍历所有机器人
for ROBOT_IP in "$@"; do
    echo "-------------------------------------------"
    ROBOT_NUM=$(echo $ROBOT_IP | awk -F. '{print $4}')
    echo "处理机器人 #$ROBOT_NUM ($ROBOT_IP)"
    echo "-------------------------------------------"
    
    # 检查机器人是否在线
    if ! ping -c 1 -W 1 $ROBOT_IP > /dev/null 2>&1; then
        echo "✗ 机器人离线或无法连接"
        echo ""
        continue
    fi
    
    echo "✓ 机器人在线"
    
    # 创建机器人目录
    ROBOT_DIR="$SESSION_DIR/robot_${ROBOT_NUM}"
    mkdir -p "$ROBOT_DIR"
    
    # 1. 同步所有日志文件
    echo "正在同步日志文件..."
    rsync -avz --progress \
        -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5" \
        --include='*.log' \
        --include='*.txt' \
        --include='*/' \
        --exclude='*' \
        nao@$ROBOT_IP:$ROBOT_LOGS_DIR/ \
        "$ROBOT_DIR/" 2>&1 | grep -E "(sending|sent|total size)" || true
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✓ 同步完成"
        
        # 统计文件
        LOG_COUNT=$(find "$ROBOT_DIR" -name "*.log" | wc -l)
        TXT_COUNT=$(find "$ROBOT_DIR" -name "*.txt" | wc -l)
        
        echo "  - .log 文件: $LOG_COUNT 个"
        echo "  - .txt 文件: $TXT_COUNT 个"
        
        # 显示最新的几个文件
        if [ $LOG_COUNT -gt 0 ] || [ $TXT_COUNT -gt 0 ]; then
            echo "  最新文件:"
            find "$ROBOT_DIR" -type f \( -name "*.log" -o -name "*.txt" \) -printf "%T@ %p\n" | \
                sort -rn | head -5 | cut -d' ' -f2- | \
                xargs -I {} bash -c 'echo "    $(basename {})"'
        fi
    else
        echo "✗ 同步失败"
    fi
    
    echo ""
done

# 创建说明文件
cat > "$SESSION_DIR/README.txt" << EOF
机器人日志提取
==============

采集时间: $(date +"%Y年%m月%d日 %H:%M:%S")
时间戳: $TIMESTAMP

机器人列表:
$(for ip in "$@"; do
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  - 机器人 #$num ($ip)"
done)

目录结构:
$(for ip in "$@"; do
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  robot_${num}/"
    if [ -d "$SESSION_DIR/robot_${num}" ]; then
        log_count=$(find "$SESSION_DIR/robot_${num}" -name "*.log" 2>/dev/null | wc -l)
        txt_count=$(find "$SESSION_DIR/robot_${num}" -name "*.txt" 2>/dev/null | wc -l)
        echo "    - .log 文件: $log_count 个"
        echo "    - .txt 文件: $txt_count 个"
    fi
done)

说明:
- 每个机器人的日志保存在独立的 robot_<编号> 目录下
- 包含所有 .log 和 .txt 文件
- 保留了机器人上的目录结构
EOF

echo "==========================================="
echo "提取完成！"
echo "==========================================="
echo "日志保存在: $SESSION_DIR"
echo ""
echo "查看日志:"
for ROBOT_IP in "$@"; do
    ROBOT_NUM=$(echo $ROBOT_IP | awk -F. '{print $4}')
    if [ -d "$SESSION_DIR/robot_${ROBOT_NUM}" ]; then
        echo "  机器人 #$ROBOT_NUM: ls -lh $SESSION_DIR/robot_${ROBOT_NUM}/"
    fi
done
echo ""
echo "说明文件: $SESSION_DIR/README.txt"
echo ""
echo "目录结构:"
tree -L 2 "$SESSION_DIR" 2>/dev/null || find "$SESSION_DIR" -maxdepth 2 -type d | sed 's|[^/]*/| |g'
