# 🤖 机器人实时状态监测功能

## 功能说明

在 GameController 界面中，双击任意机器人按钮即可弹出详细的实时状态监测窗口。

## 使用方法

### 1. 启动 GameController

```bash
cd GameController3修改版
./run_gamecontroller.sh
```

### 2. 查看机器人状态

- **单击**机器人按钮：执行原有操作（惩罚/取消惩罚/替换等）
- **双击**机器人按钮：打开状态监测弹窗

### 3. 状态监测窗口显示内容

弹窗会显示以下信息：

#### 📡 连接状态
- **Good** (绿色): 机器人在 2 秒内发送过状态消息
- **Bad** (黄色): 机器人在 2-4 秒内发送过状态消息
- **Offline** (红色): 机器人超过 4 秒未发送状态消息

#### 👕 球衣信息
- 球衣颜色
- 位置角色（守门员/场上球员）

#### ⚠️ 惩罚状态
- 当前惩罚类型
- 剩余惩罚时间（如果有）

#### 🏠 队伍信息
- 所属队伍（Home/Away）
- 机器人编号

### 4. 关闭弹窗

三种方式关闭弹窗：
1. 点击右上角的 ✕ 按钮
2. 点击底部的 "Close" 按钮
3. 按 ESC 键
4. 点击弹窗外的遮罩层

## 实现细节

### 文件结构

```
GameController3修改版/frontend/src/
├── components/
│   └── main/
│       ├── RobotStatusModal.jsx      # 新增：状态监测弹窗组件
│       ├── PlayerButton.jsx          # 修改：添加双击支持
│       └── TeamPanel.jsx             # 修改：集成弹窗功能
└── style.css                         # 修改：添加动画效果
```

### 数据流

```
机器人 (UDP 3838)
  ↓ StatusMessage
后端 (Rust)
  ↓ 解析并计算连接状态
  ↓ state event
前端 (React)
  ↓ connectionStatus
PlayerButton
  ↓ onDoubleClick
RobotStatusModal
  ↓ 显示详细信息
```

### 连接状态判定逻辑

后端根据最后一次收到 StatusMessage 的时间计算连接状态：

```rust
// connection_status.rs
const CONNECTION_STATUS_TIMEOUT_GOOD: Duration = Duration::from_secs(2);
const CONNECTION_STATUS_TIMEOUT_BAD: Duration = Duration::from_secs(4);

// 判定规则：
// time_since_last_message <= 2s  → Good
// 2s < time_since_last_message <= 4s  → Bad
// time_since_last_message > 4s  → Offline
```

## 开发和调试

### 前端开发模式

```bash
cd GameController3修改版/frontend
npm install
npm run dev
```

### 完整构建

```bash
cd GameController3修改版
cargo build --release
```

### 查看日志

```bash
# 查看 GameController 日志
tail -f GameController3修改版/logs/log_*.yaml
```

## 技术栈

- **前端框架**: React 18
- **样式**: Tailwind CSS
- **图标**: Heroicons
- **后端**: Rust + Tauri
- **通信**: Tauri IPC + Event System

## 兼容性

- ✅ 不影响现有单击功能
- ✅ 支持键盘导航（ESC 关闭）
- ✅ 响应式设计
- ✅ 实时状态更新

## 性能优化

1. **事件处理优化**
   - 双击事件使用 `stopPropagation` 防止触发单击
   - 弹窗使用 React Portal 避免 z-index 问题

2. **渲染优化**
   - 弹窗组件按需渲染
   - 使用条件渲染减少 DOM 节点

3. **动画优化**
   - CSS 动画使用 GPU 加速
   - 动画时长 200ms，流畅不卡顿

## 故障排查

### 问题 1: 双击触发了单击操作

**原因**: 事件冒泡未正确阻止

**解决**: 检查 `handleDoubleClick` 中是否调用了 `e.stopPropagation()`

### 问题 2: 连接状态不更新

**原因**: 机器人未发送 StatusMessage

**检查**:
1. 机器人是否正常运行
2. 网络连接是否正常
3. UDP 端口 3838 是否被占用

### 问题 3: 弹窗样式异常

**原因**: Tailwind CSS 未正确编译

**解决**:
```bash
cd frontend
npm run build
```

## 未来扩展

### 可能的增强功能

1. **更详细的网络信息**
   - IP 地址
   - 消息接收频率
   - 网络延迟

2. **机器人传感器数据**
   - 电池电量
   - 姿态信息
   - 温度数据

3. **历史数据图表**
   - 连接状态历史
   - 惩罚历史
   - 性能指标

4. **导出功能**
   - 导出机器人状态报告
   - 生成 CSV/JSON 数据

### 实现高级功能

如需实现上述功能，需要：

1. 扩展后端 Tauri 命令
2. 解析更多 StatusMessage 字段
3. 添加数据存储和查询功能
4. 集成图表库（如 Chart.js）

参考实现方案文档：`GC实机状态监测_实现方案.md`

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

与 GameController3 主项目保持一致

---

**版本**: 1.0.0  
**最后更新**: 2026-01-27  
**作者**: Kiro AI Assistant
