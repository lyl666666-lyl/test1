#!/bin/bash

# 快速打开最新比赛的日志可视化界面

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_LOGS_DIR="$SCRIPT_DIR/Config/Sim_Logs"

# 检查日志目录是否存在
if [ ! -d "$SIM_LOGS_DIR" ]; then
    echo "❌ 日志目录不存在: $SIM_LOGS_DIR"
    exit 1
fi

# 获取最新的比赛时间戳文件夹
LATEST_MATCH=$(ls -t "$SIM_LOGS_DIR" | head -1)

if [ -z "$LATEST_MATCH" ]; then
    echo "❌ 没有找到任何比赛日志"
    exit 1
fi

echo "📂 最新比赛: $LATEST_MATCH"
echo ""

# 列出所有队伍
TEAMS=$(ls "$SIM_LOGS_DIR/$LATEST_MATCH")

if [ -z "$TEAMS" ]; then
    echo "❌ 该比赛没有队伍日志"
    exit 1
fi

echo "🏆 可用队伍:"
i=1
declare -a team_array
for team in $TEAMS; do
    echo "  $i) $team"
    team_array[$i]=$team
    ((i++))
done
echo ""

# 如果只有一个队伍，直接打开
if [ ${#team_array[@]} -eq 1 ]; then
    SELECTED_TEAM="${team_array[1]}"
    echo "✅ 自动选择唯一队伍: $SELECTED_TEAM"
else
    # 让用户选择队伍
    read -p "请选择队伍编号 (1-${#team_array[@]}) 或 'a' 打开所有: " choice
    
    if [ "$choice" = "a" ] || [ "$choice" = "A" ]; then
        # 打开所有队伍
        for team in "${team_array[@]}"; do
            HTML_FILE="$SIM_LOGS_DIR/$LATEST_MATCH/$team/view_logs.html"
            if [ -f "$HTML_FILE" ]; then
                echo "🌐 打开 $team 的日志..."
                xdg-open "$HTML_FILE" &
                sleep 0.5
            else
                echo "⚠️  $team 没有可视化界面文件"
            fi
        done
        exit 0
    fi
    
    # 验证输入
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#team_array[@]} ]; then
        echo "❌ 无效的选择"
        exit 1
    fi
    
    SELECTED_TEAM="${team_array[$choice]}"
fi

# 打开选中队伍的可视化界面
HTML_FILE="$SIM_LOGS_DIR/$LATEST_MATCH/$SELECTED_TEAM/view_logs.html"

if [ ! -f "$HTML_FILE" ]; then
    echo "❌ 可视化界面文件不存在: $HTML_FILE"
    echo ""
    echo "💡 提示: 可视化界面会在比赛开始时自动生成"
    echo "   如果文件不存在，可以运行以下命令手动生成："
    echo "   ./generate_html_for_existing_logs.sh"
    exit 1
fi

echo "🌐 正在打开 $SELECTED_TEAM 的日志可视化界面..."
xdg-open "$HTML_FILE"

echo "✅ 完成！"
echo ""
echo "📊 日志路径: $SIM_LOGS_DIR/$LATEST_MATCH/$SELECTED_TEAM/"
