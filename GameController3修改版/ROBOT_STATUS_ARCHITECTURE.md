# 🏗️ 机器人状态监测 - 架构设计

## 系统架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         GameController                          │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Frontend (React)                       │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │              Main.jsx (主界面)                       │ │ │
│  │  │                                                      │ │ │
│  │  │  ┌────────────────────────────────────────────────┐ │ │ │
│  │  │  │         TeamPanel.jsx (队伍面板)              │ │ │ │
│  │  │  │                                                │ │ │ │
│  │  │  │  状态管理:                                     │ │ │ │
│  │  │  │  - selectedRobotForStatus                     │ │ │ │
│  │  │  │  - setSelectedRobotForStatus                  │ │ │ │
│  │  │  │                                                │ │ │ │
│  │  │  │  ┌──────────────────────────────────────────┐ │ │ │ │
│  │  │  │  │   PlayerButton.jsx (机器人按钮)         │ │ │ │ │
│  │  │  │  │                                          │ │ │ │ │
│  │  │  │  │   事件:                                  │ │ │ │ │
│  │  │  │  │   - onClick (单击)                       │ │ │ │ │
│  │  │  │  │   - onDoubleClick (双击) ───────────┐   │ │ │ │ │
│  │  │  │  │                                      │   │ │ │ │ │
│  │  │  │  │   显示:                              │   │ │ │ │ │
│  │  │  │  │   - 机器人编号                       │   │ │ │ │ │
│  │  │  │  │   - 连接状态图标                     │   │ │ │ │ │
│  │  │  │  │   - 惩罚信息                         │   │ │ │ │ │
│  │  │  │  └──────────────────────────────────────┘   │ │ │ │ │
│  │  │  │                                              │ │ │ │ │
│  │  │  │  ┌──────────────────────────────────────────┘ │ │ │ │
│  │  │  │  │                                              │ │ │ │
│  │  │  │  ▼                                              │ │ │ │
│  │  │  │  ┌──────────────────────────────────────────┐ │ │ │ │
│  │  │  │  │ RobotStatusModal.jsx (状态弹窗) ✨新增 │ │ │ │ │
│  │  │  │  │                                          │ │ │ │ │
│  │  │  │  │  显示内容:                               │ │ │ │ │
│  │  │  │  │  ┌────────────────────────────────────┐ │ │ │ │ │
│  │  │  │  │  │ Robot #5 - Home Team          [×] │ │ │ │ │ │
│  │  │  │  │  ├────────────────────────────────────┤ │ │ │ │ │
│  │  │  │  │  │ Connection: ● Good                │ │ │ │ │ │
│  │  │  │  │  │ Team Side: home                   │ │ │ │ │ │
│  │  │  │  │  │ Jersey: Blue (Field Player)       │ │ │ │ │ │
│  │  │  │  │  │ Penalty: Ball Holding             │ │ │ │ │ │
│  │  │  │  │  │ Time Remaining: 00:25             │ │ │ │ │ │
│  │  │  │  │  │                                   │ │ │ │ │ │
│  │  │  │  │  │ [Close]                           │ │ │ │ │ │
│  │  │  │  │  └────────────────────────────────────┘ │ │ │ │ │
│  │  │  │  │                                          │ │ │ │ │
│  │  │  │  │  交互:                                   │ │ │ │ │
│  │  │  │  │  - ESC 键关闭                            │ │ │ │ │
│  │  │  │  │  - 点击遮罩关闭                          │ │ │ │ │
│  │  │  │  │  - 点击关闭按钮                          │ │ │ │ │
│  │  │  │  └──────────────────────────────────────────┘ │ │ │ │
│  │  │  └────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                   Backend (Rust + Tauri)                  │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │         game_controller_runtime                     │ │ │
│  │  │                                                      │ │ │
│  │  │  event_loop() {                                     │ │ │
│  │  │    - 接收 StatusMessage (UDP 3838)                  │ │ │
│  │  │    - 更新 AlivenessTimestampMap                     │ │ │
│  │  │    - 计算 ConnectionStatusMap                       │ │ │
│  │  │    - 发送 UiState 到前端                            │ │ │
│  │  │  }                                                   │ │ │
│  │  │                                                      │ │ │
│  │  │  ┌──────────────────────────────────────────────┐  │ │ │
│  │  │  │   connection_status.rs                       │  │ │ │
│  │  │  │                                              │  │ │ │
│  │  │  │   ConnectionStatus:                          │  │ │ │
│  │  │  │   - Offline = 0 (> 4s)                       │  │ │ │
│  │  │  │   - Bad = 1 (2-4s)                           │  │ │ │
│  │  │  │   - Good = 2 (< 2s)                          │  │ │ │
│  │  │  └──────────────────────────────────────────────┘  │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │         game_controller_net                         │ │ │
│  │  │                                                      │ │ │
│  │  │  StatusMessageReceiver {                            │ │ │
│  │  │    - 监听 UDP 3838                                  │ │ │
│  │  │    - 解析 StatusMessage                             │ │ │
│  │  │    - 发送 Event::StatusMessage                      │ │ │
│  │  │  }                                                   │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
                              │ UDP 3838
                              │ StatusMessage
                              │
                    ┌─────────┴─────────┐
                    │                   │
              ┌─────▼─────┐       ┌─────▼─────┐
              │  Robot 1  │       │  Robot 2  │
              │           │       │           │
              │  发送状态  │       │  发送状态  │
              │  消息     │       │  消息     │
              └───────────┘       └───────────┘
```

## 数据流图

```
┌──────────────┐
│   Robot      │ 发送 StatusMessage (UDP 3838)
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Backend: StatusMessageReceiver                          │
│  - 接收 UDP 消息                                          │
│  - 解析 StatusMessage                                     │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Backend: event_loop()                                   │
│  - 更新 AlivenessTimestampMap[(side, player)] = now      │
│  - 计算 ConnectionStatusMap                              │
│    * time_since < 2s  → Good (2)                         │
│    * 2s < time_since < 4s  → Bad (1)                     │
│    * time_since > 4s  → Offline (0)                      │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Backend: send_ui_state()                                │
│  - 构造 UiState {                                         │
│      connection_status: ConnectionStatusMap,             │
│      game: Game,                                         │
│      legal_actions: Vec<bool>,                           │
│      undo_actions: Vec<VAction>                          │
│    }                                                     │
└──────┬───────────────────────────────────────────────────┘
       │
       │ Tauri Event: "state"
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Frontend: listenForState(handler)                       │
│  - 接收 state event                                       │
│  - 更新 React state                                       │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Frontend: Main.jsx                                      │
│  - setConnectionStatus(state.connectionStatus)           │
│  - setGame(state.game)                                   │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Frontend: TeamPanel.jsx                                 │
│  - 接收 connectionStatus prop                            │
│  - 传递给 PlayerButton                                    │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Frontend: PlayerButton.jsx                              │
│  - 显示连接状态图标                                       │
│    * Good: ✓ 绿色                                        │
│    * Bad: ⚠ 黄色                                         │
│    * Offline: ✗ 红色                                     │
│  - 监听双击事件                                           │
└──────┬───────────────────────────────────────────────────┘
       │
       │ 用户双击
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Frontend: handleDoubleClick()                           │
│  - e.stopPropagation()                                   │
│  - onDoubleClick(player)                                 │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Frontend: TeamPanel.jsx                                 │
│  - setSelectedRobotForStatus(player)                     │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  Frontend: RobotStatusModal.jsx ✨                       │
│  - 渲染弹窗                                               │
│  - 显示详细信息:                                          │
│    * 机器人编号                                           │
│    * 连接状态 (实时)                                      │
│    * 球衣颜色                                             │
│    * 惩罚状态                                             │
│    * 惩罚时间 (实时倒计时)                                │
└───────────────────────────────────────────────────────────┘
```

## 事件处理流程

```
用户操作
   │
   ├─ 单击机器人按钮
   │     │
   │     ▼
   │  onClick() → handlePlayerClick()
   │     │
   │     ├─ 选择替换球员
   │     ├─ 惩罚球员
   │     └─ 取消惩罚
   │
   └─ 双击机器人按钮
         │
         ▼
      onDoubleClick() → handleDoubleClick()
         │
         ├─ e.stopPropagation() ← 防止触发单击
         │
         ▼
      setSelectedRobotForStatus(player)
         │
         ▼
      渲染 RobotStatusModal
         │
         ├─ 显示机器人信息
         ├─ 实时更新状态
         │
         └─ 等待关闭操作
               │
               ├─ ESC 键 → onClose()
               ├─ 关闭按钮 → onClose()
               └─ 点击遮罩 → onClose()
                     │
                     ▼
                  setSelectedRobotForStatus(null)
                     │
                     ▼
                  弹窗消失
```

## 组件层级结构

```
Main.jsx
└── TeamPanel.jsx (Home)
    ├── ActionButton (Substitute)
    ├── ActionButton (Timeout)
    ├── ActionButton (Goal)
    ├── TeamStats
    ├── PlayerButton (Robot #1)
    │   └── ConnectionStatusIndicatorIcon
    ├── PlayerButton (Robot #2)
    │   └── ConnectionStatusIndicatorIcon
    ├── ...
    ├── PlayerButton (Robot #20)
    │   └── ConnectionStatusIndicatorIcon
    ├── FreeKickButtons
    └── RobotStatusModal ✨ (条件渲染)
        ├── Header
        │   ├── Title
        │   └── Close Button
        ├── Content
        │   ├── Connection Status Card
        │   ├── Team Side Card
        │   ├── Jersey Info Card
        │   └── Penalty Status Card
        └── Footer
            └── Close Button
```

## 状态管理

### TeamPanel State

```javascript
// 原有状态
const [substitute, setSubstitute] = useState(false);
const [substitutedPlayer, setSubstitutedPlayer] = useState(null);
const [forceUnpenalize, setForceUnpenalize] = useState(false);

// 新增状态 ✨
const [selectedRobotForStatus, setSelectedRobotForStatus] = useState(null);
```

### 状态流转

```
初始状态: selectedRobotForStatus = null
   │
   │ 用户双击机器人按钮
   │
   ▼
selectedRobotForStatus = player 对象
   │
   │ 触发 React 重新渲染
   │
   ▼
RobotStatusModal 显示
   │
   │ 用户关闭弹窗
   │
   ▼
selectedRobotForStatus = null
   │
   │ 触发 React 重新渲染
   │
   ▼
RobotStatusModal 消失
```

## 连接状态计算

### 后端逻辑 (Rust)

```rust
// connection_status.rs

pub fn get_connection_status_map(
    timestamps: &AlivenessTimestampMap,
    now: &Instant,
) -> ConnectionStatusMap {
    for (key, value) in timestamps {
        let time_since_alive = now.duration_since(*value);
        
        let status = if time_since_alive <= CONNECTION_STATUS_TIMEOUT_GOOD {
            ConnectionStatus::Good  // 2
        } else if time_since_alive <= CONNECTION_STATUS_TIMEOUT_BAD {
            ConnectionStatus::Bad   // 1
        } else {
            ConnectionStatus::Offline  // 0
        };
        
        result[key.0][key.1] = status;
    }
}
```

### 前端映射 (JavaScript)

```javascript
// RobotStatusModal.jsx

const connectionStatusInfo = {
  0: { label: "Offline", color: "text-red-600", bgColor: "bg-red-100" },
  1: { label: "Bad", color: "text-yellow-600", bgColor: "bg-yellow-100" },
  2: { label: "Good", color: "text-green-600", bgColor: "bg-green-100" },
};
```

## 性能考虑

### 渲染优化

```
1. 条件渲染
   - 弹窗仅在需要时渲染
   - 使用 {condition && <Component />}

2. 事件优化
   - stopPropagation 防止事件冒泡
   - 避免不必要的重新渲染

3. 状态更新
   - 使用 useState 局部状态
   - 避免全局状态污染
```

### 内存管理

```
1. 组件卸载
   - 弹窗关闭时自动清理
   - 无内存泄漏

2. 事件监听
   - 使用 React 合成事件
   - 自动清理监听器
```

## 扩展性设计

### 当前实现（方案 1）

```
数据来源: UiState (已有)
显示内容: 基本信息
实现复杂度: 低
```

### 未来扩展（方案 2）

```
数据来源: 新增 Tauri 命令
显示内容: 详细信息 + 历史数据
实现复杂度: 中等

需要添加:
1. 后端命令: get_robot_details()
2. 数据存储: 历史记录
3. 前端组件: 图表展示
```

## 技术决策

### 为什么选择模态框？

1. **不影响主界面**: 浮层显示，不占用空间
2. **聚焦信息**: 用户注意力集中在机器人状态
3. **易于实现**: React 条件渲染即可
4. **用户习惯**: 符合常见 UI 模式

### 为什么使用双击？

1. **不冲突**: 单击保留原有功能
2. **直观**: 双击查看详情是常见交互
3. **易于发现**: 用户容易尝试
4. **可扩展**: 未来可添加右键菜单

### 为什么不使用 Tauri 命令？

1. **数据已有**: UiState 包含所需信息
2. **实时更新**: 自动跟随状态变化
3. **简单高效**: 无需额外通信
4. **性能更好**: 减少 IPC 调用

## 总结

这个架构设计：

✅ **简洁**: 最小化修改，复用现有数据  
✅ **高效**: 无额外网络请求，实时更新  
✅ **可维护**: 模块化设计，职责清晰  
✅ **可扩展**: 预留扩展接口，易于增强  

---

**设计者**: Kiro AI Assistant  
**版本**: 1.0.0  
**日期**: 2026-01-27
