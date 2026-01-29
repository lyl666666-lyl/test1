#!/bin/bash

# 按队伍提取最新日志（简化版）
# 使用方法: ./extract_team_logs_simple.sh <时间范围(分钟,默认10)>
# 
# 在脚本中配置机器人信息（见下方 TEAM_A 和 TEAM_B）

PROJECT_DIR="/home/lyl/test/MyBuman"
LOCAL_LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"
ROBOT_LOGS_DIR="/home/nao/logs"

# ============================================
# 配置区域 - 在这里配置你的机器人
# ============================================

# 队伍A配置: "IP:队内位置"
# 例如: "10.0.70.1:1" 表示 10.0.70.1 是队内1号位
TEAM_A=(
    "10.0.70.15:3"    # 15号机器人，队内3号位
    # "10.0.70.2:2"   # 取消注释并修改IP和位置
    # "10.0.70.3:3"
    # "10.0.70.4:4"
    # "10.0.70.5:5"
)

# 队伍B配置: "IP:队内位置"
TEAM_B=(
    "10.0.70.13:3"    # 13号机器人，队内3号位
    # "10.0.70.7:2"
    #"10.0.70.13:3"
    # "10.0.70.9:4"
    # "10.0.70.10:5"
)

# ============================================
# 以下代码无需修改
# ============================================

# 时间范围
TIME_RANGE=${1:-10}

# 生成时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SESSION_DIR="$LOCAL_LOGS_DIR/${TIMESTAMP}"

echo "==========================================="
echo "按队伍提取最新日志"
echo "==========================================="
echo "时间戳: $TIMESTAMP"
echo "时间范围: 最近 ${TIME_RANGE} 分钟"
echo "保存目录: $SESSION_DIR"
echo "==========================================="
echo ""

# 创建目录
mkdir -p "$SESSION_DIR/TeamA"
mkdir -p "$SESSION_DIR/TeamB"

# 处理队伍A
if [ ${#TEAM_A[@]} -gt 0 ]; then
    echo "-------------------------------------------"
    echo "队伍A (${#TEAM_A[@]} 个机器人)"
    echo "-------------------------------------------"
    
    for entry in "${TEAM_A[@]}"; do
        # 跳过注释行
        [[ $entry =~ ^#.*$ ]] && continue
        [[ -z $entry ]] && continue
        
        ip=$(echo $entry | cut -d: -f1)
        pos=$(echo $entry | cut -d: -f2)
        robot_num=$(echo $ip | awk -F. '{print $4}')
        
        echo ""
        echo "位置 $pos - 机器人 #$robot_num ($ip)"
        
        # 检查在线
        if ! ping -c 1 -W 1 $ip > /dev/null 2>&1; then
            echo "  ✗ 离线"
            continue
        fi
        
        echo "  ✓ 在线"
        
        # 创建目录
        ROBOT_DIR="$SESSION_DIR/TeamA/player${pos}_robot${robot_num}"
        mkdir -p "$ROBOT_DIR"
        
        # 查找最近的文件（只要 .txt 文件）
        echo "  查找日志..."
        
        RECENT_FILES=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            nao@$ip \
            "find $ROBOT_LOGS_DIR -type f -name '*.txt' -mmin -${TIME_RANGE} 2>/dev/null")
        
        if [ -z "$RECENT_FILES" ]; then
            echo "  ✗ 未找到最近 ${TIME_RANGE} 分钟的日志"
            continue
        fi
        
        FILE_COUNT=$(echo "$RECENT_FILES" | wc -l)
        echo "  ✓ 找到 $FILE_COUNT 个文件，下载中..."
        
        # 下载文件
        downloaded=0
        echo "$RECENT_FILES" | while read file; do
            if [ -n "$file" ]; then
                if scp -q -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                    nao@$ip:"$file" "$ROBOT_DIR/" 2>/dev/null; then
                    downloaded=$((downloaded + 1))
                fi
            fi
        done
        
        # 生成增强版日志
        echo "  生成增强版日志..."
        for team_comm_file in "$ROBOT_DIR"/team_comm_p*.txt; do
            if [ -f "$team_comm_file" ]; then
                enhanced_file="${team_comm_file%.txt}_enhanced.txt"
                
                # 复制原始内容
                cat "$team_comm_file" > "$enhanced_file"
                
                # 添加分隔线
                echo "" >> "$enhanced_file"
                echo "========================================" >> "$enhanced_file"
                echo "从 bhumand 日志提取的额外信息" >> "$enhanced_file"
                echo "========================================" >> "$enhanced_file"
                echo "" >> "$enhanced_file"
                
                # 查找对应的 bhumand 日志
                for bhumand_file in "$ROBOT_DIR"/bhumand_*.log; do
                    if [ -f "$bhumand_file" ]; then
                        # 提取电池警告
                        battery_warnings=$(grep -i "battery\|电池" "$bhumand_file" 2>/dev/null)
                        if [ -n "$battery_warnings" ]; then
                            echo "## 电池电量警告" >> "$enhanced_file"
                            echo "$battery_warnings" | head -20 >> "$enhanced_file"
                            echo "" >> "$enhanced_file"
                        fi
                        
                        # 提取温度警告
                        temp_warnings=$(grep -i "temperature\|温度\|°C" "$bhumand_file" 2>/dev/null)
                        if [ -n "$temp_warnings" ]; then
                            echo "## 温度警告" >> "$enhanced_file"
                            echo "$temp_warnings" | head -20 >> "$enhanced_file"
                            echo "" >> "$enhanced_file"
                        fi
                        
                        # 提取机器人状态
                        state_changes=$(grep -i "fallen\|upright\|staggering\|倒地\|站立" "$bhumand_file" 2>/dev/null)
                        if [ -n "$state_changes" ]; then
                            echo "## 机器人状态变化" >> "$enhanced_file"
                            echo "$state_changes" | head -20 >> "$enhanced_file"
                            echo "" >> "$enhanced_file"
                        fi
                        
                        # 提取启动信息
                        startup_info=$(grep -i "team\|player\|队伍\|球员" "$bhumand_file" 2>/dev/null | head -10)
                        if [ -n "$startup_info" ]; then
                            echo "## 启动信息" >> "$enhanced_file"
                            echo "$startup_info" >> "$enhanced_file"
                            echo "" >> "$enhanced_file"
                        fi
                    fi
                done
                
                # 如果没有找到额外信息
                if ! grep -q "## " "$enhanced_file" 2>/dev/null; then
                    echo "（未找到 bhumand 日志或无额外信息）" >> "$enhanced_file"
                fi
            fi
        done
        
        echo "  ✓ 完成"
    done
    echo ""
fi

# 处理队伍B
if [ ${#TEAM_B[@]} -gt 0 ]; then
    echo "-------------------------------------------"
    echo "队伍B (${#TEAM_B[@]} 个机器人)"
    echo "-------------------------------------------"
    
    for entry in "${TEAM_B[@]}"; do
        # 跳过注释行
        [[ $entry =~ ^#.*$ ]] && continue
        [[ -z $entry ]] && continue
        
        ip=$(echo $entry | cut -d: -f1)
        pos=$(echo $entry | cut -d: -f2)
        robot_num=$(echo $ip | awk -F. '{print $4}')
        
        echo ""
        echo "位置 $pos - 机器人 #$robot_num ($ip)"
        
        # 检查在线
        if ! ping -c 1 -W 1 $ip > /dev/null 2>&1; then
            echo "  ✗ 离线"
            continue
        fi
        
        echo "  ✓ 在线"
        
        # 创建目录
        ROBOT_DIR="$SESSION_DIR/TeamB/player${pos}_robot${robot_num}"
        mkdir -p "$ROBOT_DIR"
        
        # 查找最近的文件（只要 .txt 文件）
        echo "  查找日志..."
        
        RECENT_FILES=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            nao@$ip \
            "find $ROBOT_LOGS_DIR -type f -name '*.txt' -mmin -${TIME_RANGE} 2>/dev/null")
        
        if [ -z "$RECENT_FILES" ]; then
            echo "  ✗ 未找到最近 ${TIME_RANGE} 分钟的日志"
            continue
        fi
        
        FILE_COUNT=$(echo "$RECENT_FILES" | wc -l)
        echo "  ✓ 找到 $FILE_COUNT 个文件，下载中..."
        
        # 下载文件
        echo "$RECENT_FILES" | while read file; do
            if [ -n "$file" ]; then
                scp -q -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                    nao@$ip:"$file" "$ROBOT_DIR/" 2>/dev/null
            fi
        done
        
        # 生成增强版日志
        echo "  生成增强版日志..."
        for team_comm_file in "$ROBOT_DIR"/team_comm_p*.txt; do
            if [ -f "$team_comm_file" ]; then
                enhanced_file="${team_comm_file%.txt}_enhanced.txt"
                
                # 复制原始内容
                cat "$team_comm_file" > "$enhanced_file"
                
                # 添加分隔线
                echo "" >> "$enhanced_file"
                echo "========================================" >> "$enhanced_file"
                echo "从 bhumand 日志提取的额外信息" >> "$enhanced_file"
                echo "========================================" >> "$enhanced_file"
                echo "" >> "$enhanced_file"
                
                # 查找对应的 bhumand 日志
                for bhumand_file in "$ROBOT_DIR"/bhumand_*.log; do
                    if [ -f "$bhumand_file" ]; then
                        # 提取电池警告
                        battery_warnings=$(grep -i "battery\|电池" "$bhumand_file" 2>/dev/null)
                        if [ -n "$battery_warnings" ]; then
                            echo "## 电池电量警告" >> "$enhanced_file"
                            echo "$battery_warnings" | head -20 >> "$enhanced_file"
                            echo "" >> "$enhanced_file"
                        fi
                        
                        # 提取温度警告
                        temp_warnings=$(grep -i "temperature\|温度\|°C" "$bhumand_file" 2>/dev/null)
                        if [ -n "$temp_warnings" ]; then
                            echo "## 温度警告" >> "$enhanced_file"
                            echo "$temp_warnings" | head -20 >> "$enhanced_file"
                            echo "" >> "$enhanced_file"
                        fi
                        
                        # 提取机器人状态
                        state_changes=$(grep -i "fallen\|upright\|staggering\|倒地\|站立" "$bhumand_file" 2>/dev/null)
                        if [ -n "$state_changes" ]; then
                            echo "## 机器人状态变化" >> "$enhanced_file"
                            echo "$state_changes" | head -20 >> "$enhanced_file"
                            echo "" >> "$enhanced_file"
                        fi
                        
                        # 提取启动信息
                        startup_info=$(grep -i "team\|player\|队伍\|球员" "$bhumand_file" 2>/dev/null | head -10)
                        if [ -n "$startup_info" ]; then
                            echo "## 启动信息" >> "$enhanced_file"
                            echo "$startup_info" >> "$enhanced_file"
                            echo "" >> "$enhanced_file"
                        fi
                    fi
                done
                
                # 如果没有找到额外信息
                if ! grep -q "## " "$enhanced_file" 2>/dev/null; then
                    echo "（未找到 bhumand 日志或无额外信息）" >> "$enhanced_file"
                fi
            fi
        done
        
        echo "  ✓ 完成"
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
$(for entry in "${TEAM_A[@]}"; do
    [[ $entry =~ ^#.*$ ]] && continue
    [[ -z $entry ]] && continue
    ip=$(echo $entry | cut -d: -f1)
    pos=$(echo $entry | cut -d: -f2)
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  位置 $pos - 机器人 #$num ($ip)"
done | sort)

队伍B:
$(for entry in "${TEAM_B[@]}"; do
    [[ $entry =~ ^#.*$ ]] && continue
    [[ -z $entry ]] && continue
    ip=$(echo $entry | cut -d: -f1)
    pos=$(echo $entry | cut -d: -f2)
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  位置 $pos - 机器人 #$num ($ip)"
done | sort)

目录结构:
$(tree -L 2 "$SESSION_DIR" 2>/dev/null || find "$SESSION_DIR" -type d | sed 's|[^/]*/| |g')
EOF

echo "==========================================="
echo "提取完成！"
echo "==========================================="
echo "日志保存在: $SESSION_DIR"
echo ""
echo "目录结构:"
echo "  TeamA/"
ls -1 "$SESSION_DIR/TeamA/" 2>/dev/null | while read dir; do
    count=$(ls -1 "$SESSION_DIR/TeamA/$dir/" 2>/dev/null | wc -l)
    echo "    $dir/ ($count 个文件)"
done
echo "  TeamB/"
ls -1 "$SESSION_DIR/TeamB/" 2>/dev/null | while read dir; do
    count=$(ls -1 "$SESSION_DIR/TeamB/$dir/" 2>/dev/null | wc -l)
    echo "    $dir/ ($count 个文件)"
done
echo ""
echo "说明文件: $SESSION_DIR/README.txt"
