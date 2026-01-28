#!/bin/bash

# 自动监控日志目录，为新比赛生成独立查看器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_LOGS_DIR="$SCRIPT_DIR/Config/Sim_Logs"

echo "🔍 自动生成独立查看器服务已启动"
echo "📂 监控目录: $SIM_LOGS_DIR"
echo "⏱️  每30秒检查一次新比赛"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 记录已处理的目录
PROCESSED_FILE="$SCRIPT_DIR/.processed_matches"
touch "$PROCESSED_FILE"

while true; do
    # 查找所有比赛目录
    for match_dir in "$SIM_LOGS_DIR"/*; do
        if [ ! -d "$match_dir" ]; then
            continue
        fi
        
        match_name=$(basename "$match_dir")
        
        # 检查是否已处理
        if grep -q "^$match_name$" "$PROCESSED_FILE"; then
            continue
        fi
        
        # 检查比赛是否有日志文件
        has_logs=false
        for team_dir in "$match_dir"/*; do
            if [ -d "$team_dir" ]; then
                log_count=$(ls "$team_dir"/team_comm_p*.txt 2>/dev/null | wc -l)
                if [ "$log_count" -gt 0 ]; then
                    has_logs=true
                    break
                fi
            fi
        done
        
        if [ "$has_logs" = false ]; then
            continue
        fi
        
        echo "🆕 发现新比赛: $match_name"
        echo "⏳ 等待日志写入完成..."
        
        # 等待日志文件稳定（大小不再变化）
        stable_count=0
        last_size=0
        while [ $stable_count -lt 3 ]; do
            current_size=$(find "$match_dir" -name "team_comm_p*.txt" -exec stat -c%s {} \; | awk '{s+=$1} END {print s}')
            
            if [ "$current_size" = "$last_size" ]; then
                stable_count=$((stable_count + 1))
            else
                stable_count=0
            fi
            
            last_size=$current_size
            sleep 2
        done
        
        echo "✅ 日志写入完成"
        echo "⚙️  正在生成独立查看器..."
        
        # 生成独立查看器
        python3 "$SCRIPT_DIR/create_standalone_viewer.py" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ 独立查看器生成完成"
            echo "$match_name" >> "$PROCESSED_FILE"
        else
            echo "❌ 生成失败"
        fi
        
        echo ""
    done
    
    sleep 30
done
