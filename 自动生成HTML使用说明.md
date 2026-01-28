# 🎯 自动生成可双击打开的HTML日志查看器

## 📋 功能说明

比赛结束后，**自动生成**可以直接双击打开的HTML文件，无需任何手动操作。

---

## 🚀 使用方法

### 1️⃣ 启动自动生成服务（只需运行一次）

```bash
./start_auto_viewer_service.sh
```

**服务会在后台运行**，自动监控新比赛并生成HTML文件。

### 2️⃣ 正常进行比赛

使用SimRobot进行比赛，无需任何额外操作。

### 3️⃣ 比赛结束后

- **等待约10-20秒**，服务会自动检测到新比赛
- **自动生成HTML文件**（等待日志写入完成后）
- **自动打开文件管理器**，显示生成的HTML文件所在目录

### 4️⃣ 查看日志

直接**双击** `view_logs_standalone.html` 文件即可在浏览器中查看完整日志！

---

## 📂 文件位置

生成的HTML文件位于：

```
Config/Sim_Logs/
└── [比赛时间戳]/
    ├── Team5/
    │   └── view_logs_standalone.html  ← 双击打开
    └── Team70/
        └── view_logs_standalone.html  ← 双击打开
```

---

## 🔧 管理服务

### 查看服务状态

```bash
# 查看服务日志
tail -f .auto_viewer_service.log
```

### 停止服务

```bash
./stop_auto_viewer_service.sh
```

### 重启服务

```bash
./stop_auto_viewer_service.sh
./start_auto_viewer_service.sh
```

---

## 🐛 故障排查

### 问题1：HTML文件中没有数据（显示0条记录）

**原因**：服务在日志写入完成前就生成了HTML

**解决方案**：
```bash
# 手动重新生成所有HTML文件
python3 create_standalone_viewer.py
```

### 问题2：服务没有自动生成HTML

**检查服务是否运行**：
```bash
cat .auto_viewer_service.pid
ps -p $(cat .auto_viewer_service.pid)
```

**查看日志**：
```bash
tail -20 .auto_viewer_service.log
```

### 问题3：想立即生成HTML（不等待自动服务）

```bash
# 手动生成所有比赛的HTML文件
python3 create_standalone_viewer.py
```

---

## ✨ 特性

- ✅ **完全自动化**：比赛结束后自动生成
- ✅ **智能等待**：等待日志写入完成后再生成
- ✅ **离线可用**：双击打开，无需HTTP服务器
- ✅ **完整数据**：包含所有通信记录
- ✅ **自动打开**：生成完成后自动打开文件夹

---

## 📝 工作流程

```
1. 启动服务 (./start_auto_viewer_service.sh)
   ↓
2. 进行比赛 (SimRobot)
   ↓
3. 比赛结束，日志写入
   ↓
4. 服务检测到新比赛
   ↓
5. 等待日志文件稳定（大小不再变化）
   ↓
6. 自动生成HTML文件
   ↓
7. 自动打开文件管理器
   ↓
8. 双击HTML文件查看日志 ✅
```

---

## 💡 推荐工作流

**第一次使用**：
```bash
# 1. 启动自动生成服务
./start_auto_viewer_service.sh

# 2. 进行比赛
# （使用SimRobot正常比赛）

# 3. 比赛结束后，文件管理器会自动打开
# 4. 双击 view_logs_standalone.html 查看日志
```

**日常使用**：
- 服务会一直在后台运行
- 每次比赛结束后自动生成HTML
- 直接双击打开即可

**关机前**：
```bash
# 停止服务（可选）
./stop_auto_viewer_service.sh
```

---

## 🎉 完成！

现在你可以专注于比赛，日志查看完全自动化！
