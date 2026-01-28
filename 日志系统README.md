# 机器人日志系统 - 完整指南

## 📚 文档索引

### 🚀 快速开始
- **[快速开始-日志可视化.md](快速开始-日志可视化.md)** - 最简单的使用方法，从这里开始！

### 📖 详细文档
1. **[日志可视化界面说明.md](日志可视化界面说明.md)** - 可视化界面的详细使用说明
2. **[日志可视化功能总结.md](日志可视化功能总结.md)** - 技术实现和功能总结
3. **[真实机器人自动日志配置指南.md](真实机器人自动日志配置指南.md)** - 真实机器人日志配置
4. **[机器人日志提取使用说明.md](机器人日志提取使用说明.md)** - 日志提取工具说明

## 🎯 核心功能

### 1. SimRobot 日志可视化（推荐）

**一键启动：**
```bash
./start_log_viewer.sh
```

**功能特性：**
- ✅ 自动生成可视化HTML界面
- ✅ 自动加载所有机器人日志
- ✅ 实时统计和筛选
- ✅ 美观的现代化界面
- ✅ 支持关键词搜索

**适用场景：**
- 比赛复盘分析
- 策略优化
- 通信频率分析
- 问题诊断

### 2. 真实机器人日志提取

**快速提取：**
```bash
./extract_team_logs_simple.sh
```

**功能特性：**
- ✅ 自动从机器人提取日志
- ✅ 按时间戳组织
- ✅ 支持多机器人批量提取
- ✅ 自动生成可视化界面

## 🛠️ 可用工具

### 日志查看工具
| 工具 | 用途 | 使用方法 |
|------|------|----------|
| `create_standalone_viewer.sh` | 生成可双击打开的独立查看器（推荐） | `./create_standalone_viewer.sh` |
| `start_log_viewer.sh` | 启动HTTP服务器查看日志 | `./start_log_viewer.sh` |
| `open_latest_logs.sh` | 快速打开最新日志 | `./open_latest_logs.sh` |
| `generate_html_for_existing_logs.sh` | 为已有日志生成HTML | `./generate_html_for_existing_logs.sh` |

### 日志提取工具
| 工具 | 用途 | 使用方法 |
|------|------|----------|
| `extract_team_logs_simple.sh` | 简单提取团队日志 | `./extract_team_logs_simple.sh` |
| `extract_team_logs.sh` | 完整提取团队日志 | `./extract_team_logs.sh` |
| `extract_robot_logs.sh` | 提取单个机器人日志 | `./extract_robot_logs.sh` |
| `extract_latest_logs.sh` | 提取最新日志 | `./extract_latest_logs.sh` |

### 日志管理工具
| 工具 | 用途 | 使用方法 |
|------|------|----------|
| `sync_robot_logs.sh` | 同步机器人日志 | `./sync_robot_logs.sh` |
| `sync_team_comm_logs.sh` | 同步团队通信日志 | `./sync_team_comm_logs.sh` |
| `organize_logs.sh` | 整理日志文件 | `./organize_logs.sh` |
| `watch_robot_logs.sh` | 实时监控日志 | `./watch_robot_logs.sh` |

### 配置工具
| 工具 | 用途 | 使用方法 |
|------|------|----------|
| `setup_robot_logging.sh` | 配置机器人日志 | `./setup_robot_logging.sh` |
| `update_nfs_ip.sh` | 更新NFS IP地址 | `./update_nfs_ip.sh` |

## 📂 目录结构

```
MyBuman/
├── Config/
│   ├── Sim_Logs/              # SimRobot日志
│   │   └── 20250128_143025/   # 比赛时间戳
│   │       ├── Team5/         # 队伍1
│   │       │   ├── team_comm_p1.txt
│   │       │   ├── team_comm_p2.txt
│   │       │   ├── team_comm_p3.txt
│   │       │   ├── team_comm_p4.txt
│   │       │   ├── team_comm_p5.txt
│   │       │   └── view_logs.html  # 可视化界面
│   │       └── Team70/        # 队伍2
│   │           └── ...
│   └── Real_Logs/             # 真实机器人日志
│       └── 20250128_135947/   # 提取时间戳
│           └── TeamA/         # 队伍
│               ├── player1_robot12/
│               ├── player2_robot13/
│               └── ...
├── Src/                       # 源代码
│   └── Modules/
│       └── Communication/
│           └── TeamMessageHandler/
│               ├── TeamMessageHandler.h
│               └── TeamMessageHandler.cpp
└── 工具脚本/
    ├── start_log_viewer.sh
    ├── extract_team_logs_simple.sh
    └── ...
```

## 🚀 快速开始指南

### SimRobot 日志查看（推荐方式）

**方式1：独立查看器（可双击打开）**

1. **生成独立查看器**
   ```bash
   ./create_standalone_viewer.sh
   ```

2. **双击打开**
   - 进入 `Config/Sim_Logs/[时间戳]/Team5/`
   - 双击 `view_logs_standalone.html`
   - 浏览器自动打开并显示日志

**方式2：HTTP服务器（实时更新）**

1. **启动查看器**
   ```bash
   ./start_log_viewer.sh
   ```

2. **在浏览器中分析**
   - 自动打开 `http://localhost:8000/view_logs.html`
   - 刷新页面查看最新数据
   - 按 Ctrl+C 停止服务器

### 真实机器人日志提取

1. **确保机器人在线**
   ```bash
   ping 10.1.24.12  # 测试连接
   ```

2. **提取日志**
   ```bash
   ./extract_team_logs_simple.sh
   ```

3. **查看日志**
   ```bash
   cd Config/Real_Logs/最新时间戳/TeamA/
   # 查看各个机器人的日志
   ```

## ⚠️ 重要提示

### SimRobot 日志可视化
- ✅ **view_logs_standalone.html** - 可以直接双击打开（推荐）
- ❌ **view_logs.html** - 需要HTTP服务器，不能直接双击
- 💡 使用 `./create_standalone_viewer.sh` 生成可双击的版本

### 真实机器人日志
- 需要配置SSH密钥认证
- 需要正确的机器人IP地址
- 需要NFS挂载（可选）

## 🔧 系统要求

### 必需
- Python 3（用于HTTP服务器）
- Bash（脚本运行环境）
- 现代浏览器（Chrome、Firefox、Edge等）

### 可选
- SSH（真实机器人日志提取）
- NFS（真实机器人日志同步）
- rsync（日志同步）

## 📊 日志内容

每条日志包含：
- 📤/📥 消息类型（发送/接收）
- ⏱️ 时间戳
- 🤖 机器人编号
- 📍 位置和朝向
- ⚽ 球的位置和可见度
- 👤 机器人角色
- 🎯 传球目标和行走目标
- 💰 消息预算剩余

## 🎓 学习路径

1. **新手**：从 [快速开始-日志可视化.md](快速开始-日志可视化.md) 开始
2. **进阶**：阅读 [日志可视化界面说明.md](日志可视化界面说明.md)
3. **高级**：查看 [日志可视化功能总结.md](日志可视化功能总结.md)
4. **真机**：参考 [真实机器人自动日志配置指南.md](真实机器人自动日志配置指南.md)

## 🐛 故障排除

### 问题：浏览器显示"没有找到匹配的日志"
**解决**：
- 如果打开的是 `view_logs.html`：使用 `./start_log_viewer.sh`
- 如果想直接双击打开：使用 `./create_standalone_viewer.sh` 生成 `view_logs_standalone.html`

### 问题：提示"未找到 python3"
**解决**：`sudo apt install python3`

### 问题：无法连接到机器人
**解决**：
1. 检查网络连接：`ping 机器人IP`
2. 检查SSH配置：`ssh nao@机器人IP`
3. 查看防火墙设置

### 问题：端口8000被占用
**解决**：
```bash
lsof -i :8000  # 查看占用进程
kill -9 <PID>  # 关闭进程
```

## 📞 获取帮助

1. 查看相关文档（见上方文档索引）
2. 检查脚本输出的错误信息
3. 查看浏览器控制台（F12）的错误

## 🎉 开始使用

最简单的方式：
```bash
./start_log_viewer.sh
```

就这么简单！享受日志分析的乐趣吧！ 🚀
