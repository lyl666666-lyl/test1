#!/bin/bash

# GameController 快速启动脚本
# Quick launch script for GameController

echo "=========================================="
echo "启动 GameController (带全部暂停按钮)"
echo "Starting GameController with Pause All button"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# 检查编译是否完成
if [ ! -f "target/release/game_controller_app" ]; then
    echo "❌ 未找到编译好的程序！"
    echo "❌ Compiled binary not found!"
    echo ""
    echo "请先运行编译脚本："
    echo "Please run the build script first:"
    echo "  ./build_with_pause_button.sh"
    echo ""
    exit 1
fi

echo "✅ 找到编译好的程序"
echo "✅ Found compiled binary"
echo ""
echo "正在启动 GameController..."
echo "Starting GameController..."
echo ""

# 运行 GameController
./target/release/game_controller_app

echo ""
echo "GameController 已退出"
echo "GameController exited"
