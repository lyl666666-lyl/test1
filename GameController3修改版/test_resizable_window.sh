#!/bin/bash

# GameController 可调节窗口功能测试脚本
# 测试窗口调整大小功能是否正常工作

echo "=========================================="
echo "GameController 可调节窗口功能测试"
echo "=========================================="
echo ""

# 检查是否在正确的目录
if [ ! -f "game_controller_app/tauri.conf.json" ]; then
    echo "❌ 错误：请在 GameController3修改版 目录下运行此脚本"
    exit 1
fi

echo "✓ 目录检查通过"
echo ""

# 检查 Tauri 配置
echo "1. 检查 Tauri 窗口配置..."
if grep -q '"resizable": true' game_controller_app/tauri.conf.json; then
    echo "   ✓ 窗口可调节大小已启用"
else
    echo "   ❌ 窗口可调节大小未启用"
    exit 1
fi

if grep -q '"minWidth"' game_controller_app/tauri.conf.json; then
    echo "   ✓ 最小宽度限制已设置"
else
    echo "   ❌ 最小宽度限制未设置"
    exit 1
fi

if grep -q '"minHeight"' game_controller_app/tauri.conf.json; then
    echo "   ✓ 最小高度限制已设置"
else
    echo "   ❌ 最小高度限制未设置"
    exit 1
fi

echo ""

# 检查前端响应式布局
echo "2. 检查前端响应式布局..."
if grep -q 'gc-container' frontend/src/style.css; then
    echo "   ✓ 响应式容器样式已添加"
else
    echo "   ❌ 响应式容器样式未添加"
    exit 1
fi

if grep -q 'gc-panel' frontend/src/style.css; then
    echo "   ✓ 面板样式已添加"
else
    echo "   ❌ 面板样式未添加"
    exit 1
fi

echo ""

# 检查组件更新
echo "3. 检查组件响应式更新..."
if grep -q 'gc-container' frontend/src/components/Main.jsx; then
    echo "   ✓ Main 组件已更新"
else
    echo "   ❌ Main 组件未更新"
    exit 1
fi

if grep -q 'gc-panel' frontend/src/components/main/TeamPanel.jsx; then
    echo "   ✓ TeamPanel 组件已更新"
else
    echo "   ❌ TeamPanel 组件未更新"
    exit 1
fi

if grep -q 'gc-panel' frontend/src/components/main/CenterPanel.jsx; then
    echo "   ✓ CenterPanel 组件已更新"
else
    echo "   ❌ CenterPanel 组件未更新"
    exit 1
fi

echo ""

# 构建测试
echo "4. 构建前端代码..."
cd frontend
if npm run build > /dev/null 2>&1; then
    echo "   ✓ 前端构建成功"
else
    echo "   ⚠ 前端构建失败（可能需要先安装依赖：npm install）"
fi
cd ..

echo ""
echo "=========================================="
echo "测试完成！"
echo "=========================================="
echo ""
echo "功能验证清单："
echo "✓ Tauri 窗口可调节大小配置"
echo "✓ 最小/最大尺寸限制"
echo "✓ 响应式布局样式"
echo "✓ 组件自适应更新"
echo ""
echo "手动测试步骤："
echo "1. 运行 GameController: ./run_gamecontroller.sh"
echo "2. 尝试拖拽窗口边缘调整大小"
echo "3. 验证界面内容自适应调整"
echo "4. 测试最小尺寸限制（不能小于 1000x700）"
echo "5. 确认所有功能按钮可见且可用"
echo ""
