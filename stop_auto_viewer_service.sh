#!/bin/bash

# 停止自动生成查看器服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.auto_viewer_service.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "⚠️  服务未运行"
    exit 0
fi

PID=$(cat "$PID_FILE")

if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "⚠️  服务未运行 (PID文件存在但进程不存在)"
    rm "$PID_FILE"
    exit 0
fi

echo "🛑 正在停止服务 (PID: $PID)..."
kill "$PID"

# 等待进程结束
for i in {1..5}; do
    if ! ps -p "$PID" > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

# 如果还没结束，强制杀死
if ps -p "$PID" > /dev/null 2>&1; then
    echo "⚠️  进程未响应，强制终止..."
    kill -9 "$PID"
fi

rm "$PID_FILE"
echo "✅ 服务已停止"
