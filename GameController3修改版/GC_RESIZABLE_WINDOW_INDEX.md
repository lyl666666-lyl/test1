# GameController 可调节窗口功能 - 文档索引

## 📚 文档导航

### 快速开始

1. **[快速参考](GC_RESIZABLE_WINDOW_QUICK_REFERENCE.md)** ⭐ 推荐首先阅读
   - 一句话总结
   - 核心功能
   - 快速测试
   - 常见问题

### 详细文档

2. **[功能说明](GC_RESIZABLE_WINDOW_README.md)**
   - 功能概述
   - 主要特性
   - 技术实现
   - 使用指南
   - 测试验证
   - 故障排除

3. **[实现总结](GC_RESIZABLE_WINDOW_IMPLEMENTATION_SUMMARY.md)**
   - 实现概述
   - 需求达成情况
   - 技术实现细节
   - 布局响应策略
   - 性能分析
   - 代码统计

4. **[架构设计](GC_RESIZABLE_WINDOW_ARCHITECTURE.md)**
   - 系统架构
   - 布局层次结构
   - 响应式布局流程
   - 尺寸约束系统
   - 宽度/高度分配算法
   - 性能优化策略

### 测试工具

5. **[测试脚本](test_resizable_window.sh)**
   - 自动化配置检查
   - 样式验证
   - 组件更新验证
   - 构建测试

## 📖 阅读路径

### 路径 1：快速了解（5 分钟）

```
快速参考 → 运行测试脚本 → 手动测试
```

适合：想快速了解功能并验证的用户

### 路径 2：深入理解（30 分钟）

```
快速参考 → 功能说明 → 实现总结 → 架构设计
```

适合：需要深入了解实现细节的开发者

### 路径 3：问题排查（10 分钟）

```
快速参考 → 功能说明（故障排除部分） → 测试脚本
```

适合：遇到问题需要排查的用户

## 🎯 按需查找

### 我想了解...

| 需求 | 推荐文档 | 章节 |
|-----|---------|------|
| 功能是什么 | 快速参考 | 核心功能 |
| 如何使用 | 功能说明 | 使用指南 |
| 如何测试 | 快速参考 / 功能说明 | 快速测试 / 测试验证 |
| 技术实现 | 实现总结 | 技术实现细节 |
| 架构设计 | 架构设计 | 系统架构 |
| 性能如何 | 实现总结 | 性能分析 |
| 遇到问题 | 功能说明 | 故障排除 |
| 代码改动 | 实现总结 | 代码统计 |
| 布局原理 | 架构设计 | 布局层次结构 |
| 响应式逻辑 | 架构设计 | 响应式布局流程 |

## 📁 文件清单

### 文档文件

```
GameController3修改版/
├── GC_RESIZABLE_WINDOW_INDEX.md              # 本文档（索引）
├── GC_RESIZABLE_WINDOW_QUICK_REFERENCE.md    # 快速参考
├── GC_RESIZABLE_WINDOW_README.md             # 详细说明
├── GC_RESIZABLE_WINDOW_IMPLEMENTATION_SUMMARY.md  # 实现总结
├── GC_RESIZABLE_WINDOW_ARCHITECTURE.md       # 架构设计
└── test_resizable_window.sh                  # 测试脚本
```

### 代码文件

```
GameController3修改版/
├── game_controller_app/
│   └── tauri.conf.json                       # Tauri 窗口配置
├── frontend/
│   ├── src/
│   │   ├── style.css                         # 全局样式
│   │   ├── index.jsx                         # 入口文件
│   │   └── components/
│   │       ├── Main.jsx                      # 主布局
│   │       └── main/
│   │           ├── TeamPanel.jsx             # 队伍面板
│   │           ├── CenterPanel.jsx           # 中央面板
│   │           └── UndoPanel.jsx             # 撤销面板
```

## 🔍 关键概念

### 核心技术

- **Tauri**：跨平台桌面应用框架，提供原生窗口控制
- **React**：前端 UI 框架，组件化开发
- **Flexbox**：CSS 弹性布局，实现响应式设计
- **Tailwind CSS**：实用优先的 CSS 框架

### 关键术语

| 术语 | 说明 |
|-----|------|
| 可调节窗口 | 用户可以拖拽边缘/角落调整窗口大小 |
| 响应式布局 | 界面内容根据窗口大小自动调整 |
| Flexbox | CSS 弹性盒子布局模型 |
| gc-container | 主容器样式类，垂直 Flexbox |
| gc-panel | 面板样式类，带平滑过渡 |
| flex-1 | Flex 项目，占据剩余空间 |
| flex-shrink-0 | Flex 项目，不收缩 |
| min-w / max-w | 最小/最大宽度约束 |
| overflow-y-auto | 垂直方向自动滚动 |

## 📊 功能矩阵

| 功能 | 状态 | 文档位置 |
|-----|------|---------|
| 窗口可调节大小 | ✅ | 快速参考 |
| 最小尺寸限制 | ✅ | 功能说明 - 主要特性 |
| 布局自适应 | ✅ | 架构设计 - 响应式布局流程 |
| 平滑过渡 | ✅ | 实现总结 - 性能分析 |
| 功能完整性 | ✅ | 功能说明 - 交互一致性 |
| 跨平台支持 | ✅ | 实现总结 - 兼容性 |
| 性能优化 | ✅ | 架构设计 - 性能优化策略 |
| 自动化测试 | ✅ | test_resizable_window.sh |

## 🚀 快速命令

### 测试

```bash
# 运行自动化测试
cd GameController3修改版
./test_resizable_window.sh

# 启动 GameController
./run_gamecontroller.sh
```

### 构建

```bash
# 构建前端
cd frontend
npm run build

# 构建完整应用
cd ..
cargo build --release
```

### 开发

```bash
# 启动前端开发服务器
cd frontend
npm run dev

# 启动 Tauri 开发模式
cd ..
cargo tauri dev
```

## 📝 更新日志

### v1.0.0 (2026-01-27)

- ✅ 实现窗口可调节大小功能
- ✅ 添加最小/最大尺寸限制
- ✅ 实现响应式布局
- ✅ 优化面板自适应
- ✅ 添加测试脚本
- ✅ 完善文档体系

## 🤝 贡献

如果你发现问题或有改进建议，请：

1. 查看 [故障排除](GC_RESIZABLE_WINDOW_README.md#故障排除) 章节
2. 运行 [测试脚本](test_resizable_window.sh) 验证配置
3. 查看 [实现总结](GC_RESIZABLE_WINDOW_IMPLEMENTATION_SUMMARY.md#已知限制) 了解已知限制
4. 提交问题报告或改进建议

## 📞 相关资源

### 内部文档

- [GameController 主文档](README.md)
- [机器人状态监测功能](ROBOT_STATUS_MONITOR_README.md)
- [暂停按钮功能](PAUSE_BUTTON_README.md)

### 外部资源

- [Tauri 官方文档](https://tauri.app/)
- [React 官方文档](https://react.dev/)
- [Tailwind CSS 文档](https://tailwindcss.com/)
- [CSS Flexbox 指南](https://css-tricks.com/snippets/css/a-guide-to-flexbox/)

## 📄 许可证

与 GameController 主项目保持一致

---

**维护者**：Kiro AI Assistant  
**最后更新**：2026-01-27  
**版本**：v1.0.0

---

## 快速链接

- [← 返回主文档](README.md)
- [快速参考 →](GC_RESIZABLE_WINDOW_QUICK_REFERENCE.md)
- [功能说明 →](GC_RESIZABLE_WINDOW_README.md)
- [实现总结 →](GC_RESIZABLE_WINDOW_IMPLEMENTATION_SUMMARY.md)
- [架构设计 →](GC_RESIZABLE_WINDOW_ARCHITECTURE.md)
