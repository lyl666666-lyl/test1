#!/bin/bash

# 按队伍提取最新日志
# 使用方法: ./extract_team_logs.sh [时间范围(分钟,默认10)]
# 然后按提示输入机器人信息

PROJECT_DIR="/home/lyl/test/MyBuman"
LOCAL_LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"
ROBOT_LOGS_DIR="/home/nao/logs"

# 默认时间范围：10分钟
TIME_RANGE=${1:-10}

echo "==========================================="
echo "按队伍提取最新日志"
echo "==========================================="
echo "时间范围: 最近 ${TIME_RANGE} 分钟"
echo ""

# 输入队伍A的信息
echo "请输入队伍A的机器人信息（格式: IP 队内编号）"
echo "例如: 10.0.70.1 1"
echo "      10.0.70.2 2"
echo "输入完成后按 Ctrl+D"
echo ""
echo "队伍A:"

declare -A TEAM_A
while read -p "  机器人 IP 队内编号: " ip pos; do
    if [ -n "$ip" ] && [ -n "$pos" ]; then
        TEAM_A[$ip]=$pos
    fi
done

echo ""
echo "请输入队伍B的机器人信息（格式: IP 队内编号）"
echo "输入完成后按 Ctrl+D，如果没有队伍B直接按 Ctrl+D"
echo ""
echo "队伍B:"

declare -A TEAM_B
while read -p "  机器人 IP 队内编号: " ip pos; do
    if [ -n "$ip" ] && [ -n "$pos" ]; then
        TEAM_B[$ip]=$pos
    fi
done

# 检查是否有输入
if [ ${#TEAM_A[@]} -eq 0 ] && [ ${#TEAM_B[@]} -eq 0 ]; then
    echo ""
    echo "错误: 没有输入任何机器人信息"
    exit 1
fi

# 生成时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SESSION_DIR="$LOCAL_LOGS_DIR/${TIMESTAMP}"

echo ""
echo "==========================================="
echo "开始提取"
echo "==========================================="
echo "时间戳: $TIMESTAMP"
echo "保存目录: $SESSION_DIR"
echo ""

# 创建会话目录
mkdir -p "$SESSION_DIR/TeamA"
mkdir -p "$SESSION_DIR/TeamB"

# 处理队伍A
if [ ${#TEAM_A[@]} -gt 0 ]; then
    echo "-------------------------------------------"
    echo "队伍A"
    echo "-------------------------------------------"
    
    for ip in "${!TEAM_A[@]}"; do
        pos=${TEAM_A[$ip]}
        robot_num=$(echo $ip | awk -F. '{print $4}')
        
        echo ""
        echo "机器人 #$robot_num ($ip) - 队内位置: $pos"
        
        # 检查在线
        if ! ping -c 1 -W 1 $ip > /dev/null 2>&1; then
            echo "  ✗ 离线"
            continue
        fi
        
        echo "  ✓ 在线"
        
        # 创建目录
        ROBOT_DIR="$SESSION_DIR/TeamA/player_${pos}_robot${robot_num}"
        mkdir -p "$ROBOT_DIR"
        
        # 查找最近的文件
        echo "  查找最近 ${TIME_RANGE} 分钟的日志..."
        
        RECENT_FILES=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            nao@$ip \
            "find $ROBOT_LOGS_DIR -type f \( -name '*.log' -o -name '*.txt' \) -mmin -${TIME_RANGE} 2>/dev/null")
        
        if [ -z "$RECENT_FILES" ]; then
            echo "  ✗ 未找到最近的日志"
            continue
        fi
        
        FILE_COUNT=$(echo "$RECENT_FILES" | wc -l)
        echo "  ✓ 找到 $FILE_COUNT 个文件"
        
        # 下载文件
        echo "  下载中..."
        echo "$RECENT_FILES" | while read file; do
            if [ -n "$file" ]; then
                scp -q -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                    nao@$ip:"$file" \
                    "$ROBOT_DIR/" 2>/dev/null && echo "    ✓ $(basename $file)"
            fi
        done
    done
    echo ""
fi

# 处理队伍B
if [ ${#TEAM_B[@]} -gt 0 ]; then
    echo "-------------------------------------------"
    echo "队伍B"
    echo "-------------------------------------------"
    
    for ip in "${!TEAM_B[@]}"; do
        pos=${TEAM_B[$ip]}
        robot_num=$(echo $ip | awk -F. '{print $4}')
        
        echo ""
        echo "机器人 #$robot_num ($ip) - 队内位置: $pos"
        
        # 检查在线
        if ! ping -c 1 -W 1 $ip > /dev/null 2>&1; then
            echo "  ✗ 离线"
            continue
        fi
        
        echo "  ✓ 在线"
        
        # 创建目录
        ROBOT_DIR="$SESSION_DIR/TeamB/player_${pos}_robot${robot_num}"
        mkdir -p "$ROBOT_DIR"
        
        # 查找最近的文件
        echo "  查找最近 ${TIME_RANGE} 分钟的日志..."
        
        RECENT_FILES=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            nao@$ip \
            "find $ROBOT_LOGS_DIR -type f \( -name '*.log' -o -name '*.txt' \) -mmin -${TIME_RANGE} 2>/dev/null")
        
        if [ -z "$RECENT_FILES" ]; then
            echo "  ✗ 未找到最近的日志"
            continue
        fi
        
        FILE_COUNT=$(echo "$RECENT_FILES" | wc -l)
        echo "  ✓ 找到 $FILE_COUNT 个文件"
        
        # 下载文件
        echo "  下载中..."
        echo "$RECENT_FILES" | while read file; do
            if [ -n "$file" ]; then
                scp -q -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                    nao@$ip:"$file" \
                    "$ROBOT_DIR/" 2>/dev/null && echo "    ✓ $(basename $file)"
            fi
        done
    done
    echo ""
fi

# 创建说明文件
cat > "$SESSION_DIR/README.txt" << EOF
队伍日志提取
============

采集时间: $(date +"%Y年%m月%d日 %H:%M:%S")
时间戳: $TIMESTAMP
时间范围: 最近 ${TIME_RANGE} 分钟

队伍A:
$(for ip in "${!TEAM_A[@]}"; do
    pos=${TEAM_A[$ip]}
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  位置 $pos - 机器人 #$num ($ip)"
done | sort)

队伍B:
$(for ip in "${!TEAM_B[@]}"; do
    pos=${TEAM_B[$ip]}
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  位置 $pos - 机器人 #$num ($ip)"
done | sort)

目录结构:
  TeamA/
$(for ip in "${!TEAM_A[@]}"; do
    pos=${TEAM_A[$ip]}
    num=$(echo $ip | awk -F. '{print $4}')
    dir="player_${pos}_robot${num}"
    if [ -d "$SESSION_DIR/TeamA/$dir" ]; then
        count=$(ls -1 "$SESSION_DIR/TeamA/$dir/" 2>/dev/null | wc -l)
        echo "    $dir/ ($count 个文件)"
    fi
done | sort)

  TeamB/
$(for ip in "${!TEAM_B[@]}"; do
    pos=${TEAM_B[$ip]}
    num=$(echo $ip | awk -F. '{print $4}')
    dir="player_${pos}_robot${num}"
    if [ -d "$SESSION_DIR/TeamB/$dir" ]; then
        count=$(ls -1 "$SESSION_DIR/TeamB/$dir/" 2>/dev/null | wc -l)
        echo "    $dir/ ($count 个文件)"
    fi
done | sort)
EOF

echo "==========================================="
echo "提取完成！"
echo "==========================================="
echo "日志保存在: $SESSION_DIR"
echo ""
echo "目录结构:"
tree -L 2 "$SESSION_DIR" 2>/dev/null || find "$SESSION_DIR" -maxdepth 2 -type d | sed 's|[^/]*/| |g'
echo ""
echo "说明文件: $SESSION_DIR/README.txt"
