# SimRobot 日志系统说明

## 📋 概述

SimRobot 仿真环境会自动记录每个机器人的团队通信日志，包含机器人位置、球信息、角色、状态变化和裁判手势识别等详细信息。

## 📂 日志文件结构

```
Config/Sim_Logs/
└── [比赛时间戳]/              # 例如: 20260129_000214
    ├── Team5/                  # 队伍5
    │   ├── team_comm_p1.txt   # 1号机器人日志
    │   ├── team_comm_p2.txt   # 2号机器人日志
    │   ├── team_comm_p3.txt   # 3号机器人日志
    │   ├── team_comm_p4.txt   # 4号机器人日志
    │   └── team_comm_p5.txt   # 5号机器人日志
    └── Team70/                 # 队伍70
        ├── team_comm_p1.txt
        ├── team_comm_p2.txt
        ├── team_comm_p3.txt
        ├── team_comm_p4.txt
        └── team_comm_p5.txt
```

## 📝 日志内容格式

### 文件头信息
```
========================================
团队通信日志
比赛时间: 2026-01-29 00:02:14
队伍编号: 5
机器人编号: 1
机器人名称: SimulatedNao
日志路径: /home/lyl/test/MyBuman/Config/Sim_Logs/20260129_000214/Team5/team_comm_p1.txt
========================================
```

### 发送消息格式
```
[发送] 时间=103263ms
  机器人: 1号
  位置: (-2860, -3020) 朝向=1.58928
  球: (3082, -2945) 可见度=0%
  角色: striker
  传球目标: 3 | 行走目标: (1500, 200)
  机器人状态: upright
  裁判手势: none
  消息预算剩余: 1200
```

### 接收消息格式
```
[接收] 时间=103263ms 来自机器人2号
  位置: (-1810, 3010) 朝向=-1.56464
  球: (3045, 1832) 可见度=0%
  角色: supporter
  传球目标: -1 | 行走目标: (6, 6)
  机器人状态: upright
  裁判手势: none
```

## 📊 日志包含的信息

### 基础信息
- **时间戳**: 比赛时间（毫秒）
- **机器人编号**: 1-5号
- **位置**: (x, y) 坐标，单位mm
- **朝向**: 弧度值

### 球信息
- **球位置**: (x, y) 坐标
- **可见度**: 0-100%

### 行为信息
- **角色**: striker, supporter, defender, goalkeeper 等
- **传球目标**: 目标机器人编号，-1表示无目标
- **行走目标**: 目标位置坐标

### 🆕 新增状态信息

#### 机器人状态
- `upright` - 站立
- `fallen` - 倒地
- `staggering` - 摇晃
- `falling` - 正在倒下
- `squatting` - 下蹲
- `pickedUp` - 被拿起

#### 倒地方向（如果倒地）
- `front` - 向前倒
- `back` - 向后倒
- `left` - 向左倒
- `right` - 向右倒

示例：
```
机器人状态: fallen (方向: front)
```

#### 裁判手势识别
- `none` - 无手势
- `kickInLeft` - 左侧踢球
- `kickInRight` - 右侧踢球
- `ready` - 准备信号

### 通信预算
- **消息预算剩余**: 剩余可发送消息数量

## 🔧 代码修改说明

### 1. 禁用 HTML 可视化生成

**文件**: `Src/Modules/Communication/TeamMessageHandler/TeamMessageHandler.cpp`

**修改位置**: 第 140-147 行

**修改内容**:
```cpp
// 原代码：
// Generate visualization HTML for this team (only once per team)
std::string htmlPath = logDir + "view_logs.html";
std::ifstream checkHtml(htmlPath);
if(!checkHtml.good())
{
  generateVisualizationHTML(logDir, teamFolder);
  OUTPUT_TEXT("Generated visualization HTML: " << htmlPath);
}

// 修改后：
// HTML visualization generation disabled
// std::string htmlPath = logDir + "view_logs.html";
// std::ifstream checkHtml(htmlPath);
// if(!checkHtml.good())
// {
//   generateVisualizationHTML(logDir, teamFolder);
//   OUTPUT_TEXT("Generated visualization HTML: " << htmlPath);
// }
```

**原因**: 只保留 .txt 日志文件，不生成 HTML 可视化文件。

### 2. 添加机器人状态和裁判手势信息

**文件**: `Src/Modules/Communication/TeamMessageHandler/TeamMessageHandler.cpp`

#### 发送消息日志（第 245-260 行）

**添加内容**:
```cpp
teamCommLogFile << "  机器人状态: " << TypeRegistry::getEnumName(theFallDownState.state);
if(theFallDownState.direction != FallDownState::none)
  teamCommLogFile << " (方向: " << TypeRegistry::getEnumName(theFallDownState.direction) << ")";
teamCommLogFile << "\n";
teamCommLogFile << "  裁判手势: " << TypeRegistry::getEnumName(theRefereeSignal.signal) << "\n";
```

#### 接收消息日志（第 375-382 行）

**添加内容**:
```cpp
teamCommLogFile << "  机器人状态: " << TypeRegistry::getEnumName(msg.theFallDownState.state);
if(msg.theFallDownState.direction != FallDownState::none)
  teamCommLogFile << " (方向: " << TypeRegistry::getEnumName(msg.theFallDownState.direction) << ")";
teamCommLogFile << "\n";
teamCommLogFile << "  裁判手势: " << TypeRegistry::getEnumName(msg.theRefereeSignal.signal) << "\n";
```

### 3. 依赖的表示（Representations）

日志系统使用了以下表示，已在 `TeamMessageHandler.h` 中声明：

```cpp
REQUIRES(FallDownState)        // 机器人倒地状态
USES(RefereeSignal)            // 裁判手势信号
```

相关头文件：
- `Src/Representations/Sensing/FallDownState.h` - 机器人状态定义
- `Src/Representations/Perception/RefereeGestures/RefereeGesture.h` - 裁判手势定义
- `Src/Representations/Modeling/RefereeSignal.h` - 裁判信号定义

## 🚀 使用方法

### 1. 编译代码
```bash
cd Make/Linux
./generate
./compile
```

### 2. 运行 SimRobot 仿真
正常运行 SimRobot 比赛，日志会自动生成。

### 3. 查看日志
比赛结束后，进入日志目录：
```bash
cd Config/Sim_Logs/[时间戳]/Team5/
cat team_comm_p1.txt
```

或使用文本编辑器打开查看。

## 📌 注意事项

1. **自动生成**: 日志在 SimRobot 启动时自动创建，无需手动操作
2. **线程安全**: 日志写入使用互斥锁保护，支持多线程环境
3. **实时刷新**: 每次写入后立即 flush，确保数据不丢失
4. **文件命名**: 按队伍和机器人编号自动命名
5. **时间戳**: 使用比赛开始时间作为目录名

## 🔍 日志分析建议

### 查看特定机器人的通信
```bash
grep "机器人: 3号" team_comm_p1.txt
```

### 查看倒地事件
```bash
grep "fallen" Config/Sim_Logs/*/Team5/*.txt
```

### 查看裁判手势识别
```bash
grep -v "裁判手势: none" Config/Sim_Logs/*/Team5/*.txt
```

### 统计消息数量
```bash
grep -c "\[发送\]" team_comm_p1.txt
grep -c "\[接收\]" team_comm_p1.txt
```

## 🗑️ 清理日志

日志文件会随着比赛增多而累积，可以定期清理：

```bash
# 删除所有 SimRobot 日志
rm -rf Config/Sim_Logs/202*

# 只保留最近3天的日志
find Config/Sim_Logs -type d -mtime +3 -exec rm -rf {} +
```

## 📚 相关文件

### 核心代码文件
- `Src/Modules/Communication/TeamMessageHandler/TeamMessageHandler.cpp` - 日志生成主逻辑
- `Src/Modules/Communication/TeamMessageHandler/TeamMessageHandler.h` - 模块定义

### 表示定义文件
- `Src/Representations/Sensing/FallDownState.h` - 机器人状态
- `Src/Representations/Perception/RefereeGestures/RefereeGesture.h` - 裁判手势
- `Src/Representations/Modeling/RefereeSignal.h` - 裁判信号

### 配置文件
- `.gitignore` - 日志目录已配置为不提交到 Git

## 🆚 与真实机器人日志的区别

| 特性 | SimRobot 日志 | 真实机器人日志 |
|------|--------------|----------------|
| 位置 | `Config/Sim_Logs/` | `Config/Real_Logs/` |
| 命名 | 按队伍编号 (Team5, Team70) | 按机器人编号 (robot13, robot15) |
| 内容 | 相同格式 | 相同格式 |
| 生成方式 | 仿真时自动生成 | 真实机器人运行时生成 |

## ✅ 总结

SimRobot 日志系统提供了完整的团队通信记录，包括：
- ✅ 机器人位置和朝向
- ✅ 球的位置和可见度
- ✅ 角色和行为信息
- ✅ 机器人状态（站立/倒地）
- ✅ 裁判手势识别
- ✅ 通信预算管理

所有信息以纯文本格式保存，便于分析和调试。
