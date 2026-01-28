# 🎯 团队通信日志查看器 - 完整指南

## 📖 简介

这是一个**完全自动化**的日志查看系统，比赛结束后自动生成可双击打开的HTML文件，无需任何手动操作。

---

## ⚡ 快速开始（3步）

### 1️⃣ 启动自动服务（只需一次）

```bash
./start_auto_viewer_service.sh
```

### 2️⃣ 进行比赛

使用SimRobot正常进行比赛，无需任何额外操作。

### 3️⃣ 查看日志

比赛结束后：
- 等待10-20秒，文件管理器会自动打开
- 双击 `view_logs_standalone.html` 文件
- 浏览器自动显示完整日志

**就这么简单！** 🎉

---

## 📂 文件结构

```
MyBuman/
├── start_auto_viewer_service.sh    # 启动自动生成服务
├── stop_auto_viewer_service.sh     # 停止服务
├── 手动生成HTML.sh                 # 手动生成HTML（可选）
├── create_standalone_viewer.py     # 核心生成脚本
│
└── Config/Sim_Logs/
    └── [比赛时间戳]/
        ├── Team5/
        │   ├── team_comm_p1.txt              # 原始日志
        │   ├── team_comm_p2.txt
        │   ├── ...
        │   └── view_logs_standalone.html     # ← 双击打开这个！
        │
        └── Team70/
            └── view_logs_standalone.html     # ← 双击打开这个！
```

---

## 🎮 使用场景

### 场景1：日常使用（推荐）

```bash
# 第一次：启动服务
./start_auto_viewer_service.sh

# 之后：直接进行比赛
# 比赛结束后自动生成HTML，双击打开即可
```

### 场景2：立即查看日志

```bash
# 比赛刚结束，想立即查看
./手动生成HTML.sh

# 选择比赛编号，或按回车生成所有
```

### 场景3：HTML显示0条记录

```bash
# 重新生成HTML
./手动生成HTML.sh

# 或直接生成所有
python3 create_standalone_viewer.py
```

---

## 🔧 服务管理

### 启动服务

```bash
./start_auto_viewer_service.sh
```

**服务功能**：
- 🔍 自动监控新比赛
- ⏳ 智能等待日志写入完成
- 📝 自动生成HTML文件
- 📂 自动打开文件管理器

### 停止服务

```bash
./stop_auto_viewer_service.sh
```

### 查看服务状态

```bash
# 查看服务日志
tail -f .auto_viewer_service.log

# 检查服务是否运行
ps -p $(cat .auto_viewer_service.pid)
```

---

## 🎨 HTML查看器功能

双击打开HTML文件后，你可以：

### 📊 查看统计信息
- 总消息数
- 发送/接收消息数量
- 参与机器人数量

### 🔍 筛选功能
- **按类型筛选**：仅发送/仅接收/全部
- **按机器人筛选**：查看特定机器人的日志
- **关键词搜索**：搜索任意内容

### 📝 详细信息
每条日志包含：
- 📍 机器人位置和朝向
- ⚽ 球的位置和可见度
- 👤 机器人角色
- 🎯 传球目标和行走目标
- 💰 消息预算（发送时）
- ⏱️ 时间戳

---

## 🐛 常见问题

### Q1: HTML文件显示0条记录？

**原因**：服务在日志写入完成前就生成了HTML

**解决**：
```bash
./手动生成HTML.sh
```

### Q2: 服务没有自动生成HTML？

**检查**：
```bash
# 查看服务是否运行
cat .auto_viewer_service.pid
ps -p $(cat .auto_viewer_service.pid)

# 查看日志
tail -20 .auto_viewer_service.log
```

**解决**：
```bash
# 重启服务
./stop_auto_viewer_service.sh
./start_auto_viewer_service.sh
```

### Q3: 想立即生成HTML，不等待自动服务？

```bash
./手动生成HTML.sh
```

### Q4: 如何为旧比赛生成HTML？

```bash
# 方法1：交互式选择
./手动生成HTML.sh

# 方法2：生成所有
python3 create_standalone_viewer.py
```

---

## 📋 命令速查表

| 功能 | 命令 |
|------|------|
| 启动自动服务 | `./start_auto_viewer_service.sh` |
| 停止自动服务 | `./stop_auto_viewer_service.sh` |
| 手动生成HTML | `./手动生成HTML.sh` |
| 生成所有HTML | `python3 create_standalone_viewer.py` |
| 查看服务日志 | `tail -f .auto_viewer_service.log` |
| 检查服务状态 | `ps -p $(cat .auto_viewer_service.pid)` |

---

## ✨ 特性

- ✅ **完全自动化**：比赛结束后自动生成
- ✅ **智能等待**：等待日志写入完成后再生成
- ✅ **离线可用**：双击打开，无需HTTP服务器
- ✅ **完整数据**：包含所有通信记录
- ✅ **美观界面**：现代化的可视化界面
- ✅ **强大筛选**：按类型、机器人、关键词筛选
- ✅ **自动打开**：生成完成后自动打开文件夹
- ✅ **手动生成**：支持立即生成或重新生成

---

## 🎯 工作原理

```
1. 启动自动服务
   ↓
2. 服务在后台监控 Config/Sim_Logs/
   ↓
3. 检测到新比赛
   ↓
4. 等待日志文件大小稳定（不再变化）
   ↓
5. 读取所有 team_comm_p*.txt 文件
   ↓
6. 将数据嵌入到HTML模板中
   ↓
7. 生成 view_logs_standalone.html
   ↓
8. 自动打开文件管理器
   ↓
9. 用户双击HTML文件查看日志 ✅
```

---

## 📚 相关文档

- `自动生成HTML使用说明.md` - 详细使用说明
- `快速命令参考.md` - 命令速查表
- `最简单的使用方法.md` - 最简使用指南

---

## 🎉 总结

**一次启动，永久自动化！**

```bash
# 只需运行一次
./start_auto_viewer_service.sh

# 之后每次比赛结束后
# 自动生成HTML → 自动打开文件夹 → 双击查看日志
```

**就是这么简单！** 🚀

---

## 💡 提示

- 服务会一直在后台运行，直到你停止它或关机
- 每次开机后需要重新启动服务
- 如果HTML显示0条记录，使用 `./手动生成HTML.sh` 重新生成
- 所有HTML文件都是独立的，可以复制到其他电脑上打开

---

**享受自动化的便利吧！** 🎊
