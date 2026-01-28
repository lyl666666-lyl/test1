#!/bin/bash

# 启动本地HTTP服务器查看日志

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_LOGS_DIR="$SCRIPT_DIR/Config/Sim_Logs"

# 检查是否安装了Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 未找到 python3，请先安装 Python"
    exit 1
fi

# 获取最新的比赛时间戳文件夹
LATEST_MATCH=$(ls -t "$SIM_LOGS_DIR" 2>/dev/null | head -1)

if [ -z "$LATEST_MATCH" ]; then
    echo "❌ 没有找到任何比赛日志"
    exit 1
fi

echo "📂 最新比赛: $LATEST_MATCH"
echo ""

# 列出所有队伍
TEAMS=$(ls "$SIM_LOGS_DIR/$LATEST_MATCH" 2>/dev/null)

if [ -z "$TEAMS" ]; then
    echo "❌ 该比赛没有队伍日志"
    exit 1
fi

echo "🏆 可用队伍:"
i=1
declare -a team_array
for team in $TEAMS; do
    if [ -d "$SIM_LOGS_DIR/$LATEST_MATCH/$team" ]; then
        echo "  $i) $team"
        team_array[$i]=$team
        ((i++))
    fi
done
echo ""

# 如果只有一个队伍，直接选择
if [ ${#team_array[@]} -eq 1 ]; then
    SELECTED_TEAM="${team_array[1]}"
    echo "✅ 自动选择唯一队伍: $SELECTED_TEAM"
else
    # 让用户选择队伍
    read -p "请选择队伍编号 (1-${#team_array[@]}): " choice
    
    # 验证输入
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#team_array[@]} ]; then
        echo "❌ 无效的选择"
        exit 1
    fi
    
    SELECTED_TEAM="${team_array[$choice]}"
fi

TEAM_DIR="$SIM_LOGS_DIR/$LATEST_MATCH/$SELECTED_TEAM"

# 检查HTML文件是否存在
if [ ! -f "$TEAM_DIR/view_logs.html" ]; then
    echo "❌ 可视化界面文件不存在"
    echo "💡 正在生成HTML文件..."
    ./generate_html_for_existing_logs.sh
fi

echo ""
echo "🌐 启动本地HTTP服务器..."
echo "📊 队伍: $SELECTED_TEAM"
echo "📁 路径: $TEAM_DIR"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 在浏览器中打开: http://localhost:8000/view_logs.html"
echo "  ⚠️  按 Ctrl+C 停止服务器"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 自动在浏览器中打开
sleep 1
xdg-open "http://localhost:8000/view_logs.html" 2>/dev/null &

# 启动HTTP服务器
cd "$TEAM_DIR"
python3 -m http.server 8000
