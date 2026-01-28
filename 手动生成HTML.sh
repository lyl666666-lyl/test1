#!/bin/bash

# 手动生成可双击打开的HTML日志查看器
# 用于立即生成HTML文件，无需等待自动服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_LOGS_DIR="$SCRIPT_DIR/Config/Sim_Logs"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔧 手动生成HTML日志查看器"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查日志目录是否存在
if [ ! -d "$SIM_LOGS_DIR" ]; then
    echo "❌ 日志目录不存在: $SIM_LOGS_DIR"
    exit 1
fi

# 获取所有比赛
MATCHES=$(ls -t "$SIM_LOGS_DIR" 2>/dev/null | grep -E '^[0-9]{8}_[0-9]{6}$')

if [ -z "$MATCHES" ]; then
    echo "❌ 没有找到任何比赛日志"
    exit 1
fi

echo "📂 可用的比赛："
echo ""
i=1
declare -a match_array
for match in $MATCHES; do
    match_array[$i]=$match
    
    # 统计队伍数量
    team_count=$(ls -d "$SIM_LOGS_DIR/$match"/*/ 2>/dev/null | wc -l)
    
    # 检查是否已有HTML文件
    html_count=$(find "$SIM_LOGS_DIR/$match" -name "view_logs_standalone.html" 2>/dev/null | wc -l)
    
    if [ $html_count -gt 0 ]; then
        status="✅ 已生成"
    else
        status="⚠️  未生成"
    fi
    
    echo "  $i) $match  ($team_count 个队伍) $status"
    ((i++))
done

echo ""
echo "  0) 生成所有比赛的HTML"
echo ""

# 用户选择
read -p "请选择要生成的比赛编号 (0-${#match_array[@]}，直接回车=0): " choice

# 默认选择0
if [ -z "$choice" ]; then
    choice=0
fi

# 验证输入
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -gt ${#match_array[@]} ]; then
    echo "❌ 无效的选择"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$choice" -eq 0 ]; then
    # 生成所有比赛
    echo "🔄 正在为所有比赛生成HTML..."
    echo ""
    python3 "$SCRIPT_DIR/create_standalone_viewer.py"
    
else
    # 生成指定比赛
    SELECTED_MATCH="${match_array[$choice]}"
    echo "🔄 正在为比赛 $SELECTED_MATCH 生成HTML..."
    echo ""
    
    MATCH_DIR="$SIM_LOGS_DIR/$SELECTED_MATCH"
    
    # 遍历每个队伍
    for team_dir in "$MATCH_DIR"/*; do
        if [ ! -d "$team_dir" ]; then
            continue
        fi
        
        team_name=$(basename "$team_dir")
        
        # 检查是否有日志文件
        log_count=$(ls "$team_dir"/team_comm_p*.txt 2>/dev/null | wc -l)
        if [ "$log_count" -eq 0 ]; then
            echo "  ⊘ $team_name - 没有日志文件"
            continue
        fi
        
        echo "  ⚙️  $team_name - 生成中..."
        
        # 读取所有日志文件
        log_files=$(ls "$team_dir"/team_comm_p*.txt 2>/dev/null)
        
        # 使用Python生成HTML（调用create_standalone_viewer.py的函数）
        python3 << EOF
import sys
sys.path.insert(0, '$SCRIPT_DIR')
from create_standalone_viewer import create_standalone_viewer

if create_standalone_viewer('$team_dir', '$team_name'):
    print('  ✅ $team_name - 生成完成')
else:
    print('  ❌ $team_name - 生成失败')
EOF
    done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ HTML生成完成！"
echo ""
echo "💡 使用方法："
echo "   1. 进入 Config/Sim_Logs/[比赛时间]/[队伍名]/"
echo "   2. 双击 view_logs_standalone.html 文件"
echo "   3. 浏览器会自动打开并显示日志"
echo ""

# 询问是否打开文件夹
read -p "是否打开文件夹？(y/n，直接回车=y): " open_folder

if [ -z "$open_folder" ] || [ "$open_folder" = "y" ] || [ "$open_folder" = "Y" ]; then
    if [ "$choice" -eq 0 ]; then
        # 打开最新比赛的第一个队伍
        latest_match="${match_array[1]}"
        first_team=$(ls -d "$SIM_LOGS_DIR/$latest_match"/*/ 2>/dev/null | head -1)
    else
        # 打开选中比赛的第一个队伍
        first_team=$(ls -d "$MATCH_DIR"/*/ 2>/dev/null | head -1)
    fi
    
    if [ -n "$first_team" ]; then
        echo ""
        echo "📂 正在打开文件夹..."
        xdg-open "$first_team" 2>/dev/null &
        echo "✅ 已打开: $first_team"
    fi
fi

echo ""
echo "🎉 完成！"
