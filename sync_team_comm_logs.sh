#!/bin/bash

# 同步团队通信日志并按时间戳和队伍分组
# 使用方法: ./sync_team_comm_logs.sh <队伍A的机器人IP列表> -- <队伍B的机器人IP列表>
# 例如: ./sync_team_comm_logs.sh 10.0.70.1 10.0.70.2 10.0.70.3 10.0.70.4 10.0.70.5 -- 10.0.70.6 10.0.70.7 10.0.70.8 10.0.70.9 10.0.70.10

PROJECT_DIR="/home/lyl/test/MyBuman"
LOCAL_LOGS_DIR="$PROJECT_DIR/Config/Real_Logs"
ROBOT_LOGS_DIR="/home/nao/logs"

# 生成时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SESSION_DIR="$LOCAL_LOGS_DIR/${TIMESTAMP}"

# 解析参数：分成两个队伍
TEAM_A=()
TEAM_B=()
current_team="A"

for arg in "$@"; do
    if [ "$arg" == "--" ]; then
        current_team="B"
    else
        if [ "$current_team" == "A" ]; then
            TEAM_A+=("$arg")
        else
            TEAM_B+=("$arg")
        fi
    fi
done

echo "==========================================="
echo "Team Communication Logs Sync"
echo "==========================================="
echo "时间戳: $TIMESTAMP"
echo "保存目录: $SESSION_DIR"
echo ""
echo "队伍A (${#TEAM_A[@]} 个机器人): ${TEAM_A[*]}"
echo "队伍B (${#TEAM_B[@]} 个机器人): ${TEAM_B[*]}"
echo "==========================================="
echo ""

# 创建会话目录
mkdir -p "$SESSION_DIR/TeamA"
mkdir -p "$SESSION_DIR/TeamB"

# 同步队伍A的日志
if [ ${#TEAM_A[@]} -gt 0 ]; then
    echo "-------------------------------------------"
    echo "同步队伍A"
    echo "-------------------------------------------"
    
    for ROBOT_IP in "${TEAM_A[@]}"; do
        ROBOT_NUM=$(echo $ROBOT_IP | awk -F. '{print $4}')
        echo "机器人 #$ROBOT_NUM ($ROBOT_IP)..."
        
        if ping -c 1 -W 1 $ROBOT_IP > /dev/null 2>&1; then
            # 同步 team_comm 日志（包括子目录中的）
            scp -r -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                nao@$ROBOT_IP:$ROBOT_LOGS_DIR/*/Team*/team_comm_*.txt \
                "$SESSION_DIR/TeamA/" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                # 重命名文件，添加机器人编号
                for file in "$SESSION_DIR/TeamA/team_comm_"*.txt; do
                    if [ -f "$file" ]; then
                        basename=$(basename "$file")
                        mv "$file" "$SESSION_DIR/TeamA/robot${ROBOT_NUM}_${basename}"
                        echo "  ✓ 已保存: robot${ROBOT_NUM}_${basename}"
                    fi
                done
            else
                echo "  ✗ 未找到日志文件"
            fi
        else
            echo "  ✗ 机器人离线"
        fi
    done
    echo ""
fi

# 同步队伍B的日志
if [ ${#TEAM_B[@]} -gt 0 ]; then
    echo "-------------------------------------------"
    echo "同步队伍B"
    echo "-------------------------------------------"
    
    for ROBOT_IP in "${TEAM_B[@]}"; do
        ROBOT_NUM=$(echo $ROBOT_IP | awk -F. '{print $4}')
        echo "机器人 #$ROBOT_NUM ($ROBOT_IP)..."
        
        if ping -c 1 -W 1 $ROBOT_IP > /dev/null 2>&1; then
            # 同步 team_comm 日志（包括子目录中的）
            scp -r -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
                nao@$ROBOT_IP:$ROBOT_LOGS_DIR/*/Team*/team_comm_*.txt \
                "$SESSION_DIR/TeamB/" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                # 重命名文件，添加机器人编号
                for file in "$SESSION_DIR/TeamB/team_comm_"*.txt; do
                    if [ -f "$file" ]; then
                        basename=$(basename "$file")
                        mv "$file" "$SESSION_DIR/TeamB/robot${ROBOT_NUM}_${basename}"
                        echo "  ✓ 已保存: robot${ROBOT_NUM}_${basename}"
                    fi
                done
            else
                echo "  ✗ 未找到日志文件"
            fi
        else
            echo "  ✗ 机器人离线"
        fi
    done
    echo ""
fi

# 创建说明文件
cat > "$SESSION_DIR/README.txt" << EOF
团队通信日志
============

采集时间: $(date +"%Y年%m月%d日 %H:%M:%S")
时间戳: $TIMESTAMP

队伍A:
$(for ip in "${TEAM_A[@]}"; do
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  - 机器人 #$num ($ip)"
done)

队伍B:
$(for ip in "${TEAM_B[@]}"; do
    num=$(echo $ip | awk -F. '{print $4}')
    echo "  - 机器人 #$num ($ip)"
done)

文件结构:
  TeamA/
    robot1_team_comm_p1.txt
    robot2_team_comm_p2.txt
    ...
  TeamB/
    robot6_team_comm_p1.txt
    robot7_team_comm_p2.txt
    ...
EOF

echo "==========================================="
echo "同步完成！"
echo "==========================================="
echo "日志保存在: $SESSION_DIR"
echo ""
echo "查看日志:"
echo "  ls -lh $SESSION_DIR/TeamA/"
echo "  ls -lh $SESSION_DIR/TeamB/"
echo ""
echo "说明文件: $SESSION_DIR/README.txt"
