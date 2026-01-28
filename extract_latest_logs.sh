#!/bin/bash

# 只提取最新的日志文件
# 使用方法: ./extract_latest_logs.sh <机器人IP列表> [时间范围(分钟,默认10)]
# 例如: ./extract_latest_logs.sh 10.0.70.11
#       ./extract_latest_logs.sh 10.0.70.11 5  # 只提取最近5分钟的

PROJECT_DIR="/home/lyl/test/MyBuman"
LOCAL_LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"
ROBOT_LOGS_DIR="/home/nao/logs"

# 默认时间范围：10分钟
TIME_RANGE=10

# 解析参数
ROBOTS=()
for arg in "$@"; do
    if [[ $arg =~ ^[0-9]+$ ]] && [ ${#ROBOTS[@]} -gt 0 ]; then
        TIME_RANGE=$arg
    else
        ROBOTS+=("$arg")
    fi
done

if [ ${#ROBOTS[@]} -eq 0 ]; then
    echo "用法: $0 <机器人IP1> [机器人IP2] ... [时间范围(分钟)]"
    echo ""
    echo "示例:"
    echo "  $0 10.0.70.11              # 提取最近10分钟的日志"
    echo "  $0 10.0.70.11 5            # 提取最近5分钟的日志"
    echo "  $0 10.0.70.6 10.0.70.11 15 # 提取两个机器人最近15分钟的日志"
    exit 1
fi

# 生成时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SESSION_DIR="$LOCAL_LOGS_DIR/${TIMESTAMP}"

echo "==========================================="
echo "提取最新日志"
echo "==========================================="
echo "时间戳: $TIMESTAMP"
echo "保存目录: $SESSION_DIR"
echo "时间范围: 最近 ${TIME_RANGE} 分钟"
echo "机器人列表: ${ROBOTS[*]}"
echo "==========================================="
echo ""

# 创建会话目录
mkdir -p "$SESSION_DIR"

# 遍历所有机器人
for ROBOT_IP in "${ROBOTS[@]}"; do
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
    
    # 在机器人上查找最近修改的文件
    echo "正在查找最近 ${TIME_RANGE} 分钟内的日志..."
    
    RECENT_FILES=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        nao@$ROBOT_IP \
        "find $ROBOT_LOGS_DIR -type f \( -name '*.log' -o -name '*.txt' \) -mmin -${TIME_RANGE} 2>/dev/null")
    
    if [ -z "$RECENT_FILES" ]; then
        echo "✗ 未找到最近 ${TIME_RANGE} 分钟内的日志文件"
        echo "  提示: 增加时间范围，例如: $0 ${ROBOT_IP} 30"
        echo ""
        continue
    fi
    
    # 统计找到的文件
    FILE_COUNT=$(echo "$RECENT_FILES" | wc -l)
    echo "✓ 找到 $FILE_COUNT 个文件"
    
    # 显示文件列表
    echo "  文件列表:"
    echo "$RECENT_FILES" | while read file; do
        echo "    - $(basename $file)"
    done
    
    # 下载这些文件
    echo ""
    echo "正在下载..."
    
    echo "$RECENT_FILES" | while read file; do
        if [ -n "$file" ]; then
            scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                nao@$ROBOT_IP:"$file" \
                "$ROBOT_DIR/" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo "  ✓ $(basename $file)"
            else
                echo "  ✗ $(basename $file) - 下载失败"
            fi
        fi
    done
    
    echo ""
    echo "✓ 机器人 #$ROBOT_NUM 完成"
    echo ""
done

# 创建说明文件
cat > "$SESSION_DIR/README.txt" << EOF
最新日志提取
============

采集时间: $(date +"%Y年%m月%d日 %H:%M:%S")
时间戳: $TIMESTAMP
时间范围: 最近 ${TIME_RANGE} 分钟

机器人列表:
$(for ip in "${ROBOTS[@]}"; do
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  - 机器人 #$num ($ip)"
done)

提取的文件:
$(for ip in "${ROBOTS[@]}"; do
    num=$(echo $ip | awk -F. '{print $4}')
    if [ -d "$SESSION_DIR/robot_${num}" ]; then
        echo "  robot_${num}:"
        ls -1 "$SESSION_DIR/robot_${num}/" 2>/dev/null | sed 's/^/    - /'
    fi
done)

说明:
- 只包含最近 ${TIME_RANGE} 分钟内修改的日志文件
- 这些是刚刚运行的测试/比赛的日志
- 如果文件太少，可以增加时间范围
EOF

echo "==========================================="
echo "提取完成！"
echo "==========================================="
echo "日志保存在: $SESSION_DIR"
echo ""

# 显示提取的文件
for ROBOT_IP in "${ROBOTS[@]}"; do
    ROBOT_NUM=$(echo $ROBOT_IP | awk -F. '{print $4}')
    if [ -d "$SESSION_DIR/robot_${ROBOT_NUM}" ]; then
        FILE_COUNT=$(ls -1 "$SESSION_DIR/robot_${ROBOT_NUM}/" 2>/dev/null | wc -l)
        if [ $FILE_COUNT -gt 0 ]; then
            echo "机器人 #$ROBOT_NUM: $FILE_COUNT 个文件"
            ls -lh "$SESSION_DIR/robot_${ROBOT_NUM}/" | tail -n +2 | awk '{print "  " $9 " (" $5 ")"}'
        fi
    fi
done

echo ""
echo "说明文件: $SESSION_DIR/README.txt"
