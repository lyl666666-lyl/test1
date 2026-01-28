#!/bin/bash

# 启动自动生成查看器服务
# 这个服务会在后台运行，监控新比赛并自动生成可双击打开的HTML
# 生成完成后会自动打开文件管理器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.auto_viewer_service.pid"
LOG_FILE="$SCRIPT_DIR/.auto_viewer_service.log"

# 检查是否已经在运行
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "⚠️  服务已经在运行 (PID: $OLD_PID)"
        echo "💡 如需重启，请先运行: ./stop_auto_viewer_service.sh"
        exit 1
    fi
fi

echo "🚀 启动自动生成查看器服务..."
echo "📂 监控目录: Config/Sim_Logs/"
echo "📝 日志文件: $LOG_FILE"
echo "🗂️  生成完成后会自动打开文件夹"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 启动后台服务
nohup bash -c '
SCRIPT_DIR="'"$SCRIPT_DIR"'"
SIM_LOGS_DIR="$SCRIPT_DIR/Config/Sim_Logs"
PROCESSED_FILE="$SCRIPT_DIR/.processed_matches"
LOG_FILE="'"$LOG_FILE"'"

touch "$PROCESSED_FILE"

echo "$(date "+%Y-%m-%d %H:%M:%S") - 服务启动" >> "$LOG_FILE"

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
        
        # 检查是否有日志文件
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
        
        echo "$(date "+%Y-%m-%d %H:%M:%S") - 🆕 发现新比赛: $match_name" >> "$LOG_FILE"
        echo "$(date "+%Y-%m-%d %H:%M:%S") - ⏳ 等待日志写入完成..." >> "$LOG_FILE"
        
        # 等待日志文件稳定（大小不再变化）
        stable_count=0
        last_size=0
        while [ $stable_count -lt 3 ]; do
            current_size=$(find "$match_dir" -name "team_comm_p*.txt" -exec stat -c%s {} \; 2>/dev/null | awk "{s+=\$1} END {print s}")
            
            if [ "$current_size" = "$last_size" ] && [ "$current_size" != "0" ]; then
                stable_count=$((stable_count + 1))
            else
                stable_count=0
            fi
            
            last_size=$current_size
            sleep 2
        done
        
        echo "$(date "+%Y-%m-%d %H:%M:%S") - ✅ 日志写入完成，开始生成HTML..." >> "$LOG_FILE"
        
        # 生成独立查看器（使用create_standalone_viewer.py）
        cd "$SCRIPT_DIR"
        python3 create_standalone_viewer.py >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            echo "$(date "+%Y-%m-%d %H:%M:%S") - ✅ 生成成功: $match_name" >> "$LOG_FILE"
            echo "$match_name" >> "$PROCESSED_FILE"
            
            # 自动打开文件管理器到第一个队伍的目录
            first_team=$(ls -d "$match_dir"/*/ 2>/dev/null | head -1)
            if [ -n "$first_team" ]; then
                # 使用xdg-open打开文件管理器
                DISPLAY=:0 xdg-open "$first_team" >> "$LOG_FILE" 2>&1
                echo "$(date "+%Y-%m-%d %H:%M:%S") - 📂 已打开文件夹: $first_team" >> "$LOG_FILE"
            fi
        else
            echo "$(date "+%Y-%m-%d %H:%M:%S") - ❌ 生成失败: $match_name" >> "$LOG_FILE"
        fi
    done
    
    sleep 10
done
' > /dev/null 2>&1 &

# 保存PID
echo $! > "$PID_FILE"

echo "✅ 服务已启动 (PID: $(cat "$PID_FILE"))"
echo ""
echo "💡 提示："
echo "   - 服务会自动监控新比赛并生成可双击打开的HTML"
echo "   - 生成完成后会自动打开文件管理器"
echo "   - 查看日志: tail -f $LOG_FILE"
echo "   - 停止服务: ./stop_auto_viewer_service.sh"
echo ""
echo "🎉 现在你可以正常运行SimRobot比赛了！"
echo "   比赛结束后，HTML文件会自动生成并打开文件夹"
