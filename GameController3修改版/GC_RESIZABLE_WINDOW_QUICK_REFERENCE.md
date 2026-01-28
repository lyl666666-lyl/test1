# GameController 可调节窗口 - 快速参考

## 一句话总结

GameController 现在支持像终端一样自由调整窗口大小，界面内容自动适配。

## 核心功能

| 功能 | 说明 |
|-----|------|
| 🖱️ 拖拽调整 | 拖拽窗口边缘/角落调整大小 |
| 📏 尺寸限制 | 最小 1000x700，默认 1400x900 |
| 🔄 自适应 | 界面内容自动调整布局 |
| ⚡ 平滑过渡 | 调整时无卡顿，体验流畅 |
| ✅ 功能完整 | 所有 GC 功能正常工作 |

## 快速测试

```bash
# 1. 运行测试脚本
cd GameController3修改版
./test_resizable_window.sh

# 2. 启动 GameController
./run_gamecontroller.sh

# 3. 手动测试
# - 拖拽窗口边缘调整大小
# - 验证界面自适应
# - 测试所有功能按钮
```

## 关键文件

| 文件 | 修改内容 |
|-----|---------|
| `game_controller_app/tauri.conf.json` | 添加窗口配置（resizable, minWidth, minHeight） |
| `frontend/src/style.css` | 添加响应式样式（gc-container, gc-panel） |
| `frontend/src/components/Main.jsx` | 更新主布局为弹性布局 |
| `frontend/src/components/main/TeamPanel.jsx` | 添加面板自适应和滚动 |
| `frontend/src/components/main/CenterPanel.jsx` | 添加中央面板弹性布局 |
| `frontend/src/components/main/UndoPanel.jsx` | 添加按钮换行支持 |

## 技术要点

### Tauri 配置
```json
{
  "windows": [{
    "width": 1400,
    "height": 900,
    "minWidth": 1000,
    "minHeight": 700,
    "resizable": true
  }]
}
```

### CSS 关键样式
```css
.gc-container {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
}

.gc-panel {
  transition: all 0.1s ease-out;
}
```

### React 布局模式
```jsx
// 主容器：垂直布局
<div className="gc-container">
  {/* 内容区：水平布局，自动填充 */}
  <div className="flex-1 flex gap-4 min-h-0">
    <TeamPanel className="flex-1 min-w-[280px] max-w-[400px]" />
    <CenterPanel className="flex-1 min-w-[300px]" />
    <TeamPanel className="flex-1 min-w-[280px] max-w-[400px]" />
  </div>
  {/* 底部面板：固定高度 */}
  <div className="flex-shrink-0">
    <UndoPanel />
  </div>
</div>
```

## 常见问题

**Q: 窗口能缩多小？**  
A: 最小 1000x700 像素，确保所有功能可用。

**Q: 调整大小会影响功能吗？**  
A: 不会，所有功能保持正常，状态不丢失。

**Q: 支持哪些操作系统？**  
A: Linux、macOS、Windows 全平台支持。

**Q: 如何恢复默认大小？**  
A: 重启应用自动恢复到 1400x900。

## 验证清单

- [ ] 窗口可以拖拽调整大小
- [ ] 最小尺寸限制生效（1000x700）
- [ ] 界面内容自适应调整
- [ ] 所有按钮可见且可用
- [ ] Pause/Resume 功能正常
- [ ] 机器人状态监测正常
- [ ] 调整大小时无卡顿
- [ ] 功能状态不丢失

## 相关文档

- 详细文档：[GC_RESIZABLE_WINDOW_README.md](GC_RESIZABLE_WINDOW_README.md)
- 测试脚本：[test_resizable_window.sh](test_resizable_window.sh)
- 主项目文档：[README.md](README.md)
