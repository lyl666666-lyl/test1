#!/bin/bash

# 整理现有日志文件
# 将 Config/Logs/ 下的日志整理到 Config/Real_Logs/ 并按队伍分组

PROJECT_DIR="/home/lyl/test/MyBuman"
SOURCE_DIR="$PROJECT_DIR/Config/Logs"
TARGET_DIR="$PROJECT_DIR/Config/Real_Logs"

echo "==========================================="
echo "整理现有日志文件"
echo "==========================================="
echo "源目录: $SOURCE_DIR"
echo "目标目录: $TARGET_DIR"
echo "==========================================="
echo ""

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "错误: 源目录不存在: $SOURCE_DIR"
    exit 1
fi

# 查找所有时间戳目录
TIMESTAMP_DIRS=$(find "$SOURCE_DIR" -maxdepth 1 -type d -name "20*" | sort)

if [ -z "$TIMESTAMP_DIRS" ]; then
    echo "未找到任何日志目录"
    exit 1
fi

echo "找到以下日志目录:"
echo "$TIMESTAMP_DIRS" | while read dir; do
    echo "  - $(basename $dir)"
done
echo ""

# 处理每个时间戳目录
echo "$TIMESTAMP_DIRS" | while read timestamp_dir; do
    timestamp=$(basename "$timestamp_dir")
    echo "-------------------------------------------"
    echo "处理: $timestamp"
    echo "-------------------------------------------"
    
    # 创建目标目录
    target_session="$TARGET_DIR/$timestamp"
    mkdir -p "$target_session"
    
    # 查找所有 Team 目录
    team_dirs=$(find "$timestamp_dir" -maxdepth 1 -type d -name "Team*" | sort)
    
    if [ -z "$team_dirs" ]; then
        echo "  未找到 Team 目录"
        echo ""
        continue
    fi
    
    # 处理每个 Team 目录
    echo "$team_dirs" | while read team_dir; do
        team_name=$(basename "$team_dir")
        team_num=$(echo "$team_name" | sed 's/Team//')
        
        echo "  队伍 $team_num ($team_name)"
        
        # 创建队伍目录（使用 TeamA, TeamB 命名）
        if [ "$team_num" -le "50" ]; then
            target_team="$target_session/TeamA"
        else
            target_team="$target_session/TeamB"
        fi
        mkdir -p "$target_team"
        
        # 查找所有 team_comm 文件
        comm_files=$(find "$team_dir" -name "team_comm_*.txt" | sort)
        
        if [ -z "$comm_files" ]; then
            echo "    未找到 team_comm 文件"
        else
            file_count=$(echo "$comm_files" | wc -l)
            echo "    找到 $file_count 个 team_comm 文件"
            
            # 复制文件
            echo "$comm_files" | while read file; do
                filename=$(basename "$file")
                # 提取队内编号
                player_num=$(echo "$filename" | sed 's/team_comm_p\([0-9]*\)\.txt/\1/')
                
                # 创建目标目录（player<编号>_team<队伍号>）
                target_player="$target_team/player${player_num}_team${team_num}"
                mkdir -p "$target_player"
                
                # 复制文件
                cp "$file" "$target_player/"
                echo "      ✓ $filename -> player${player_num}_team${team_num}/"
            done
        fi
    done
    
    # 创建说明文件
    cat > "$target_session/README.txt" << EOF
日志整理
========

原始目录: $timestamp_dir
整理时间: $(date +"%Y年%m月%d日 %H:%M:%S")
时间戳: $timestamp

目录结构:
$(tree -L 2 "$target_session" 2>/dev/null || find "$target_session" -type d | sed 's|[^/]*/| |g')

文件列表:
$(find "$target_session" -name "team_comm_*.txt" | while read f; do
    rel_path=$(echo "$f" | sed "s|$target_session/||")
    echo "  $rel_path"
done)
EOF
    
    echo "  ✓ 完成"
    echo ""
done

echo "==========================================="
echo "整理完成！"
echo "==========================================="
echo "查看结果:"
echo "  ls -lh $TARGET_DIR/"
echo ""

# 显示整理后的目录结构
echo "整理后的目录:"
for dir in $(find "$TARGET_DIR" -maxdepth 1 -type d -name "20*" | sort); do
    timestamp=$(basename "$dir")
    echo ""
    echo "  $timestamp/"
    find "$dir" -type d -maxdepth 2 | tail -n +2 | sed 's|[^/]*/|  |g'
done
