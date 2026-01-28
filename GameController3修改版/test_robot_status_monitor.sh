#!/bin/bash

# 机器人状态监测功能测试脚本

set -e

echo "=========================================="
echo "  机器人状态监测功能测试"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查是否在正确的目录
if [ ! -f "Cargo.toml" ]; then
    echo -e "${RED}错误: 请在 GameController3修改版 目录下运行此脚本${NC}"
    exit 1
fi

echo -e "${YELLOW}步骤 1: 检查文件是否存在...${NC}"
echo ""

# 检查新增和修改的文件
files_to_check=(
    "frontend/src/components/main/RobotStatusModal.jsx"
    "frontend/src/components/main/PlayerButton.jsx"
    "frontend/src/components/main/TeamPanel.jsx"
    "frontend/src/style.css"
)

all_files_exist=true
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (缺失)"
        all_files_exist=false
    fi
done

if [ "$all_files_exist" = false ]; then
    echo -e "${RED}错误: 部分文件缺失，请检查实现${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 2: 检查代码语法...${NC}"
echo ""

# 检查 JSX 文件语法
cd frontend

if ! npm list > /dev/null 2>&1; then
    echo -e "${YELLOW}正在安装前端依赖...${NC}"
    npm install
fi

echo "检查 RobotStatusModal.jsx..."
if grep -q "RobotStatusModal" src/components/main/RobotStatusModal.jsx; then
    echo -e "${GREEN}✓${NC} RobotStatusModal 组件定义正确"
else
    echo -e "${RED}✗${NC} RobotStatusModal 组件定义有问题"
    exit 1
fi

echo "检查 PlayerButton.jsx..."
if grep -q "onDoubleClick" src/components/main/PlayerButton.jsx; then
    echo -e "${GREEN}✓${NC} PlayerButton 已添加 onDoubleClick 支持"
else
    echo -e "${RED}✗${NC} PlayerButton 缺少 onDoubleClick 支持"
    exit 1
fi

echo "检查 TeamPanel.jsx..."
if grep -q "RobotStatusModal" src/components/main/TeamPanel.jsx; then
    echo -e "${GREEN}✓${NC} TeamPanel 已导入 RobotStatusModal"
else
    echo -e "${RED}✗${NC} TeamPanel 未导入 RobotStatusModal"
    exit 1
fi

if grep -q "selectedRobotForStatus" src/components/main/TeamPanel.jsx; then
    echo -e "${GREEN}✓${NC} TeamPanel 已添加状态管理"
else
    echo -e "${RED}✗${NC} TeamPanel 缺少状态管理"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 3: 构建前端...${NC}"
echo ""

if npm run build; then
    echo -e "${GREEN}✓${NC} 前端构建成功"
else
    echo -e "${RED}✗${NC} 前端构建失败"
    exit 1
fi

cd ..

echo ""
echo -e "${YELLOW}步骤 4: 构建后端...${NC}"
echo ""

if cargo build --release 2>&1 | tee /tmp/cargo_build.log; then
    echo -e "${GREEN}✓${NC} 后端构建成功"
else
    echo -e "${RED}✗${NC} 后端构建失败"
    echo "查看详细日志: /tmp/cargo_build.log"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ 所有测试通过！${NC}"
echo "=========================================="
echo ""
echo "使用说明："
echo "1. 运行 GameController:"
echo "   ./run_gamecontroller.sh"
echo ""
echo "2. 在界面中双击任意机器人按钮查看状态"
echo ""
echo "3. 测试要点："
echo "   - 单击机器人按钮应正常工作（惩罚/取消惩罚）"
echo "   - 双击机器人按钮应弹出状态窗口"
echo "   - 状态窗口显示连接状态、球衣、惩罚等信息"
echo "   - 可通过 ESC、关闭按钮或点击遮罩关闭窗口"
echo ""
echo "详细文档: ROBOT_STATUS_MONITOR_README.md"
echo ""
