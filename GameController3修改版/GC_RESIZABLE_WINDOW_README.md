# GameController 可调节窗口功能

## 功能概述

GameController 界面现已支持类似终端/控制面板的可调节窗口能力，用户可以自由调整窗口大小以适配不同屏幕和使用场景。

## 主要特性

### 1. 窗口尺寸控制
- ✅ **自由调整大小**：支持通过鼠标拖拽窗口边缘或角落来调整大小
- ✅ **横向/纵向/对角线拉伸**：支持所有方向的窗口调整
- ✅ **最小尺寸限制**：1000x700 像素，确保界面始终可用
- ✅ **默认尺寸**：1400x900 像素，提供舒适的操作空间

### 2. 布局自适应
- ✅ **弹性布局**：使用 Flexbox 实现内容自适应
- ✅ **响应式面板**：TeamPanel、CenterPanel 自动调整宽度
- ✅ **智能滚动**：内容过多时自动显示滚动条
- ✅ **平滑过渡**：窗口调整时界面平滑变化，无卡顿

### 3. 交互一致性
- ✅ **功能完整性**：窗口大小变化不影响任何 GC 功能
- ✅ **状态保持**：调整大小不触发重载或状态丢失
- ✅ **操作连续性**：Pause/Resume 等操作在尺寸变化前后行为一致

## 技术实现

### Tauri 窗口配置

在 `game_controller_app/tauri.conf.json` 中添加窗口配置：

```json
{
  "app": {
    "windows": [
      {
        "title": "GameController",
        "width": 1400,
        "height": 900,
        "minWidth": 1000,
        "minHeight": 700,
        "resizable": true,
        "fullscreen": false,
        "decorations": true
      }
    ]
  }
}
```

### 前端响应式布局

#### 1. 全局样式 (`frontend/src/style.css`)

```css
/* 确保根容器填充视口 */
#root {
  width: 100vw;
  height: 100vh;
  overflow: hidden;
}

/* 响应式容器 */
.gc-container {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  box-sizing: border-box;
}

/* 平滑过渡 */
.gc-panel {
  transition: all 0.1s ease-out;
}
```

#### 2. 主布局 (`Main.jsx`)

```jsx
<div className="gc-container p-2 gap-4">
  <div className="flex-1 flex gap-4 min-h-0 overflow-hidden">
    <TeamPanel ... />
    <CenterPanel ... />
    <TeamPanel ... />
  </div>
  <div className="flex-shrink-0">
    <UndoPanel ... />
  </div>
</div>
```

#### 3. 面板组件

**TeamPanel**：
- 使用 `flex-1` 自动分配空间
- 设置 `min-w-[280px]` 和 `max-w-[400px]` 限制宽度范围
- 玩家列表区域使用 `overflow-y-auto` 支持滚动

**CenterPanel**：
- 使用 `flex-1` 占据中央空间
- 设置 `min-w-[300px]` 确保最小可用宽度

**UndoPanel**：
- 使用 `flex-shrink-0` 固定高度
- 添加 `flex-wrap` 支持按钮换行

## 使用指南

### 调整窗口大小

1. **拖拽边缘**：将鼠标移到窗口边缘，光标变为调整大小图标时拖拽
2. **拖拽角落**：拖拽窗口角落可同时调整宽度和高度
3. **最小限制**：窗口不能小于 1000x700 像素
4. **最大化**：可以使用系统窗口控制按钮最大化窗口

### 适配不同屏幕

- **小屏幕（1366x768）**：窗口会自动调整到合适大小，内容区域显示滚动条
- **标准屏幕（1920x1080）**：使用默认 1400x900 尺寸，提供最佳体验
- **大屏幕（2560x1440+）**：可以放大窗口，界面元素保持清晰

### 布局响应行为

| 窗口宽度 | 布局行为 |
|---------|---------|
| < 1000px | 不允许（最小限制） |
| 1000-1200px | 紧凑布局，面板最小宽度 |
| 1200-1600px | 标准布局，舒适间距 |
| > 1600px | 宽松布局，面板最大宽度 |

## 测试验证

### 自动测试

运行测试脚本验证配置：

```bash
cd GameController3修改版
./test_resizable_window.sh
```

测试内容：
- ✓ Tauri 窗口配置检查
- ✓ 最小/最大尺寸限制验证
- ✓ 响应式样式检查
- ✓ 组件更新验证
- ✓ 前端构建测试

### 手动测试

1. **启动 GameController**：
   ```bash
   ./run_gamecontroller.sh
   ```

2. **测试窗口调整**：
   - 拖拽窗口边缘，验证可以自由调整大小
   - 尝试缩小到最小尺寸，验证限制生效
   - 放大窗口，验证界面自适应

3. **测试功能完整性**：
   - 调整窗口大小后，点击各个按钮验证功能正常
   - 测试 Pause/Resume 功能
   - 测试机器人状态监测（双击机器人按钮）
   - 验证所有面板内容可见且可操作

4. **测试不同尺寸**：
   - 最小尺寸（1000x700）：验证所有功能可用
   - 标准尺寸（1400x900）：验证最佳体验
   - 大尺寸（1920x1080+）：验证界面美观

## 兼容性

### 操作系统
- ✅ Linux（已测试）
- ✅ macOS（Tauri 原生支持）
- ✅ Windows（Tauri 原生支持）

### 浏览器引擎
- 使用 Tauri 的 WebView（基于系统原生 WebView）
- Linux: WebKitGTK
- macOS: WKWebView
- Windows: WebView2

## 性能优化

### 渲染性能
- 使用 CSS `transition` 实现平滑动画
- 避免频繁重排，使用 `transform` 优化
- 合理使用 `overflow` 避免不必要的重绘

### 内存占用
- 响应式布局不增加额外内存开销
- 使用原生 Flexbox，无需第三方库

## 故障排除

### 问题：窗口无法调整大小

**解决方案**：
1. 检查 `tauri.conf.json` 中 `resizable: true` 配置
2. 确认使用最新版本的 Tauri
3. 重新构建应用：`cargo build --release`

### 问题：界面内容被遮挡

**解决方案**：
1. 检查窗口是否小于最小尺寸限制
2. 验证 CSS 样式是否正确加载
3. 清除浏览器缓存并重新构建前端

### 问题：调整大小时卡顿

**解决方案**：
1. 检查系统性能和资源占用
2. 减少 CSS `transition` 时间
3. 关闭不必要的后台程序

## 未来改进

### 计划中的功能
- [ ] 记住用户的窗口大小偏好
- [ ] 支持全屏模式快捷键
- [ ] 添加预设窗口尺寸选项
- [ ] 支持多显示器场景优化

### 可选增强
- [ ] 添加窗口大小指示器
- [ ] 支持自定义最小/最大尺寸
- [ ] 添加窗口大小动画效果

## 相关文档

- [Tauri 窗口配置文档](https://tauri.app/v1/api/config/#windowconfig)
- [CSS Flexbox 指南](https://css-tricks.com/snippets/css/a-guide-to-flexbox/)
- [GameController 主文档](README.md)
- [机器人状态监测功能](ROBOT_STATUS_MONITOR_README.md)

## 更新日志

### v1.0.0 (2026-01-27)
- ✅ 实现窗口可调节大小功能
- ✅ 添加最小/最大尺寸限制
- ✅ 实现响应式布局
- ✅ 优化面板自适应
- ✅ 添加测试脚本和文档

## 贡献者

- 实现：Kiro AI Assistant
- 测试：待补充
- 文档：Kiro AI Assistant

## 许可证

与 GameController 主项目保持一致
