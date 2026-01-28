# GameController 全部暂停按钮 / Pause All Button

## 功能说明 / Feature Description

在GameController的主界面顶部添加了一个显眼的"全部暂停 / PAUSE ALL"按钮，方便在比赛过程中快速暂停所有机器人，以便观察机器人的状态。

Added a prominent "PAUSE ALL" button at the top of the GameController main interface for quickly pausing all robots during a match to observe their states.

## 修改的文件 / Modified Files

1. **frontend/src/components/main/StatePanel.jsx**
   - 添加了全部暂停按钮到状态面板顶部
   - Added pause all button to the top of the state panel

2. **frontend/src/components/main/PauseAllButton.jsx** (新文件 / New file)
   - 创建了专门的暂停按钮组件，使用黄色高亮样式
   - Created a dedicated pause button component with yellow highlight styling

## 按钮特性 / Button Features

- **位置 / Position**: 位于状态控制面板的最顶部，占据整行
- **样式 / Style**: 黄色背景，加粗字体，带有暂停图标 ⏸️
- **功能 / Function**: 点击后触发裁判暂停（Referee Timeout），暂停所有机器人
- **提示 / Tooltip**: 鼠标悬停时显示"暂停比赛以观察机器人状态"

## 使用方法 / Usage

1. 编译前端代码：
   ```bash
   cd GameController3/frontend
   npm install
   npm run build
   ```

2. 编译并运行GameController：
   ```bash
   cd GameController3
   cargo build --release
   cargo run --release
   ```

3. 在比赛界面中，点击顶部的黄色"⏸️ 全部暂停 / PAUSE ALL"按钮即可暂停比赛

## 技术实现 / Technical Implementation

- 使用现有的 `timeout` action，参数为 `{ side: null }`（裁判暂停）
- 暂停时会：
  - 取消所有球员的惩罚计时器
  - 将主计时器回退到停止时刻
  - 启动裁判暂停计时器
  - 将游戏状态设置为 `Timeout`

## 注意事项 / Notes

- 此按钮与原有的"Referee Timeout"按钮功能相同，只是更加显眼和易用
- 暂停期间可以观察机器人状态，然后通过"Ready"或"Standby"按钮恢复比赛
- 暂停功能在点球大战期间也可用
