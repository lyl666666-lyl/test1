#!/bin/bash

# 按队伍提取最新日志（简化版）
# 使用方法: ./extract_team_logs_simple.sh <时间范围(分钟,默认10)>

PROJECT_DIR="/home/lyl/test/MyBuman"
LOCAL_LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"
ROBOT_LOGS_DIR="/home/nao/logs"
ROBOT_PASSWORD="nao"

# ============================================
# 配置区域
# ============================================

TEAM_A=(
    "10.0.70.12:1"
    "10.0.70.1:2"
    #"10.0.70.12:3"
    "10.0.70.15:4"
    #"10.0.70.15:5"
)

TEAM_B=(
    #"10.0.70.13:1"
    "10.0.70.13:2"
    #"10.0.70.15:3"
    "10.0.70.14:4"
    "10.0.70.11:5"
)

# ============================================
# 函数定义
# ============================================

generate_enhanced_log_remote() {
    local remote_team_comm="$1"
    local output_file="$2"
    local robot_ip="$3"
    
    local team_comm_content=$(sshpass -p "$ROBOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        nao@$robot_ip "cat $remote_team_comm" 2>/dev/null)
    
    if [ -z "$team_comm_content" ]; then
        return 1
    fi
    
    python3 - "$output_file" << PYTHON_SCRIPT
import sys
import re
from datetime import datetime, timedelta

team_comm_content = """$team_comm_content"""

def parse_time(base_time_str, time_ms):
    try:
        base_time = datetime.strptime(base_time_str, "%Y-%m-%d %H:%M:%S")
        delta = timedelta(milliseconds=time_ms)
        result_time = base_time + delta
        return result_time.strftime("%Y-%m-%d %H:%M:%S")
    except:
        return base_time_str

def convert_role(role):
    role_map = {
        'kickOffForward': ('kickOffForward', '开球前锋'),
        'striker': ('striker', '前锋'),
        'supporter': ('supporter', '支援'),
        'defender': ('defender', '后卫'),
        'goalkeeper': ('goalkeeper', '守门员'),
    }
    return role_map.get(role, (role, role))

def convert_state(state):
    state_map = {
        'upright': '站立',
        'fallen': '倒地',
        'staggering': '摇晃',
        'falling': '正在倒下',
        'squatting': '下蹲',
        'pickedUp': '被拿起',
    }
    return state_map.get(state, state)

def rad_to_deg(rad_str):
    try:
        import math
        rad = float(rad_str)
        deg = int(rad * 180 / math.pi)
        return deg
    except:
        return 0

output_file = sys.argv[1]
lines = team_comm_content.split('\\n')

base_time = ""
team_num = ""
player_num = ""

for line in lines:
    if line.startswith("比赛时间:"):
        base_time = line.split(":", 1)[1].strip()
    elif line.startswith("队伍编号:"):
        team_num = line.split(":", 1)[1].strip()
    elif line.startswith("机器人编号:"):
        player_num = line.split(":", 1)[1].strip()

with open(output_file, 'w', encoding='utf-8') as out:
    out.write("=" * 40 + "\\n")
    out.write("团队通信日志 - 原始内容\\n")
    out.write("=" * 40 + "\\n")
    out.write("\\n")
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        match_send = re.match(r'\[发送\]\s+时间=(\d+)ms', line)
        match_recv = re.match(r'\[接收\]\s+时间=(\d+)ms\s+来自机器人(\d+)号', line)
        
        if match_send or match_recv:
            if match_send:
                time_ms = int(match_send.group(1))
                from_robot = None
            else:
                time_ms = int(match_recv.group(1))
                from_robot = match_recv.group(2)
            
            msg_data = {}
            i += 1
            while i < len(lines) and not lines[i].strip().startswith('['):
                content = lines[i].strip()
                if not content:
                    i += 1
                    continue
                
                if content.startswith("位置:"):
                    match = re.search(r'\(([^)]+)\)\s+朝向=([0-9.-]+)', content)
                    if match:
                        msg_data['position'] = match.group(1)
                        msg_data['heading'] = match.group(2)
                
                elif content.startswith("球:"):
                    match = re.search(r'\(([^)]+)\)\s+可见度=(\d+)%', content)
                    if match:
                        msg_data['ball_pos'] = match.group(1)
                        msg_data['ball_conf'] = int(match.group(2))
                
                elif content.startswith("角色:"):
                    match = re.search(r'角色:\s+(\w+)', content)
                    if match:
                        msg_data['role'] = match.group(1)
                
                elif content.startswith("传球目标:"):
                    match = re.search(r'传球目标:\s+([^|]+)\s+\|\s+行走目标:\s+\(([^)]+)\)', content)
                    if match:
                        msg_data['pass_target'] = match.group(1).strip()
                        msg_data['walk_target'] = match.group(2)
                
                elif content.startswith("机器人状态:"):
                    match = re.search(r'机器人状态:\s+(\w+)', content)
                    if match:
                        msg_data['robot_state'] = match.group(1)
                
                elif content.startswith("裁判手势:"):
                    match = re.search(r'裁判手势:\s+(\w+)', content)
                    if match:
                        msg_data['referee_gesture'] = match.group(1)
                
                i += 1
            
            timestamp = parse_time(base_time, time_ms)
            
            if from_robot:
                out.write(f"[{timestamp}] 收到队友 #{from_robot} 的消息\\n")
            else:
                out.write(f"[{timestamp}] 发送消息到队友\\n")
            
            out.write(f"  队伍号: {team_num}\\n")
            out.write(f"  球员号: {player_num}\\n")
            
            ball_pos = msg_data.get('ball_pos', '0, 0')
            ball_conf = msg_data.get('ball_conf', 0)
            confidence = ball_conf / 100.0
            out.write(f"  球位置: ({ball_pos}) 置信度: {confidence:.2f} 可见度: {ball_conf}%\\n")
            
            position = msg_data.get('position', '0, 0')
            heading = msg_data.get('heading', '0')
            heading_deg = rad_to_deg(heading)
            out.write(f"  机器人位置: ({position}, {heading_deg}°)\\n")
            
            role = msg_data.get('role', '')
            if role:
                role_en, role_cn = convert_role(role)
                out.write(f"  角色: {role_en} ({role_cn})\\n")
            
            walk_target = msg_data.get('walk_target', '')
            if walk_target and walk_target != '0,0':
                out.write(f"  行走目标: ({walk_target})\\n")
            
            pass_target = msg_data.get('pass_target', '')
            if pass_target and pass_target != '-1':
                out.write(f"  传球目标: {pass_target}\\n")
            
            robot_state = msg_data.get('robot_state', '')
            if robot_state and robot_state != 'upright':
                state_cn = convert_state(robot_state)
                out.write(f"  机器人状态: {robot_state} ({state_cn})\\n")
            
            referee_gesture = msg_data.get('referee_gesture', '')
            if referee_gesture and referee_gesture != 'none':
                out.write(f"  裁判手势: {referee_gesture}\\n")
            
            out.write("\\n")
            continue
        
        i += 1

PYTHON_SCRIPT
}

# ============================================
# 主程序
# ============================================

# 检查 sshpass 是否安装
if ! command -v sshpass &> /dev/null; then
    echo "错误: 未安装 sshpass"
    echo "请运行: sudo apt-get install sshpass"
    exit 1
fi

TIME_RANGE=${1:-10}
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

mkdir -p "$SESSION_DIR/TeamA"
mkdir -p "$SESSION_DIR/TeamB"

# 处理队伍A
if [ ${#TEAM_A[@]} -gt 0 ]; then
    echo "-------------------------------------------"
    echo "队伍A (${#TEAM_A[@]} 个机器人)"
    echo "-------------------------------------------"
    
    for entry in "${TEAM_A[@]}"; do
        [[ $entry =~ ^#.*$ ]] && continue
        [[ -z $entry ]] && continue
        
        ip=$(echo $entry | cut -d: -f1)
        pos=$(echo $entry | cut -d: -f2)
        robot_num=$(echo $ip | awk -F. '{print $4}')
        
        echo ""
        echo "位置 $pos - 机器人 #$robot_num ($ip)"
        
        if ! ping -c 1 -W 1 $ip > /dev/null 2>&1; then
            echo "  ✗ 离线"
            continue
        fi
        
        echo "  ✓ 在线"
        
        ROBOT_DIR="$SESSION_DIR/TeamA/player${pos}_robot${robot_num}"
        mkdir -p "$ROBOT_DIR"
        
        echo "  查找日志..."
        
        RECENT_TXT_FILES=$(sshpass -p "$ROBOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            nao@$ip \
            "find $ROBOT_LOGS_DIR -type f -name 'team_comm_p*.txt' -mmin -${TIME_RANGE} 2>/dev/null")
        
        if [ -z "$RECENT_TXT_FILES" ]; then
            echo "  ✗ 未找到最近 ${TIME_RANGE} 分钟的日志"
            continue
        fi
        
        FILE_COUNT=$(echo "$RECENT_TXT_FILES" | wc -l)
        echo "  ✓ 找到 $FILE_COUNT 个 team_comm 文件"
        
        echo "  远程读取并生成增强版日志..."
        echo "$RECENT_TXT_FILES" | while read remote_file; do
            if [ -n "$remote_file" ]; then
                filename=$(basename "$remote_file")
                enhanced_file="$ROBOT_DIR/${filename%.txt}_enhanced.txt"
                generate_enhanced_log_remote "$remote_file" "$enhanced_file" "$ip"
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
        [[ $entry =~ ^#.*$ ]] && continue
        [[ -z $entry ]] && continue
        
        ip=$(echo $entry | cut -d: -f1)
        pos=$(echo $entry | cut -d: -f2)
        robot_num=$(echo $ip | awk -F. '{print $4}')
        
        echo ""
        echo "位置 $pos - 机器人 #$robot_num ($ip)"
        
        if ! ping -c 1 -W 1 $ip > /dev/null 2>&1; then
            echo "  ✗ 离线"
            continue
        fi
        
        echo "  ✓ 在线"
        
        ROBOT_DIR="$SESSION_DIR/TeamB/player${pos}_robot${robot_num}"
        mkdir -p "$ROBOT_DIR"
        
        echo "  查找日志..."
        
        RECENT_TXT_FILES=$(sshpass -p "$ROBOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            nao@$ip \
            "find $ROBOT_LOGS_DIR -type f -name 'team_comm_p*.txt' -mmin -${TIME_RANGE} 2>/dev/null")
        
        if [ -z "$RECENT_TXT_FILES" ]; then
            echo "  ✗ 未找到最近 ${TIME_RANGE} 分钟的日志"
            continue
        fi
        
        FILE_COUNT=$(echo "$RECENT_TXT_FILES" | wc -l)
        echo "  ✓ 找到 $FILE_COUNT 个 team_comm 文件"
        
        echo "  远程读取并生成增强版日志..."
        echo "$RECENT_TXT_FILES" | while read remote_file; do
            if [ -n "$remote_file" ]; then
                filename=$(basename "$remote_file")
                enhanced_file="$ROBOT_DIR/${filename%.txt}_enhanced.txt"
                generate_enhanced_log_remote "$remote_file" "$enhanced_file" "$ip"
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

说明:
- 只生成 team_comm_p*_enhanced.txt 文件（仅包含团队通信日志）
- 所有日志通过远程读取生成（不占用本地空间）
- 自动使用密码连接（密码: nao）
- 不包含 bhumand 额外信息

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
