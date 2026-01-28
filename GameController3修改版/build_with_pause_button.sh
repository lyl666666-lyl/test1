#!/bin/bash

# GameController 编译脚本（包含全部暂停按钮）
# Build script for GameController with Pause All button

echo "=========================================="
echo "编译 GameController (带全部暂停按钮)"
echo "Building GameController with Pause All button"
echo "=========================================="

# 进入 GameController3 目录
cd "$(dirname "$0")"

# 1. 编译前端
echo ""
echo "步骤 1/2: 编译前端..."
echo "Step 1/2: Building frontend..."
cd frontend

# 检查 node_modules 是否存在
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    echo "Installing frontend dependencies..."
    npm install
fi

# 编译前端
npm run build
if [ $? -ne 0 ]; then
    echo "❌ 前端编译失败！"
    echo "❌ Frontend build failed!"
    exit 1
fi

echo "✅ 前端编译成功"
echo "✅ Frontend build successful"

# 2. 编译后端
cd ..
echo ""
echo "步骤 2/2: 编译后端..."
echo "Step 2/2: Building backend..."

cargo build --release
if [ $? -ne 0 ]; then
    echo "❌ 后端编译失败！"
    echo "❌ Backend build failed!"
    exit 1
fi

echo "✅ 后端编译成功"
echo "✅ Backend build successful"

echo ""
echo "=========================================="
echo "✅ 编译完成！"
echo "✅ Build complete!"
echo "=========================================="
echo ""
echo "运行 GameController:"
echo "Run GameController:"
echo "  cargo run --release"
echo ""
echo "或者使用编译好的二进制文件:"
echo "Or use the compiled binary:"
echo "  ./target/release/game_controller_app"
echo ""
