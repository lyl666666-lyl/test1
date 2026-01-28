# SimRobot外部(gc)控制的实现

## 概述
比较原本由内部命令控制simrobot，实现了通过外部gc控制simrobot

## 1.替换SimulatedNao

**目录：** Src/Libs/SimulatedNao
**替换内容：** 
```
SimulatedNao/GameController.h
SimulatedNao/GameController.cpp
```
-   新增UDP套接字成员变量
-   新增外部GameController启用/禁用方法
-   新增UDP消息处理方法
-   新增机器人状态发送方法
-   修改状态管理逻辑以支持外部控制

```
SimulatedNao/ConsoleRoboCupCtrl.cpp
SimulatedNao/ConsoleRoboCupCtrl.h
```
-   在命令处理中添加  `gc external on/off`  命令
-   集成CommandServer的TCP命令服务器

```
SimulatedNao/CommandServer.cpp
SimulatedNao/CommandServer.h
```
-   TCP服务器实现，用于接收外部命令
-   命令队列管理
-   客户端连接处理

```
SimulatedNao/Network/UdpComm.h
SimulatedNao/Network/UdpComm.cpp
```
- 这些文件提供UDP通信的基础功能

`SimulatedNao/Representations/Communication/GameControllerData.h`
- 定义与外部GameController通信的数据结构

```
SimulatedNao/RemoteConsole.h
SimulatedNao/RemoteConsole.cpp
```
-   远程机器人连接的UDP通信支持

```
SimulatedNao/RoboCupCtrl.h
SimulatedNao/RoboCupCtrl.cpp
```
-   集成GameController和CommandServer
-   初始化UDP通信组件

**拉取连接：** http://212.64.83.115:5244/ye/SimulatedNao


## 2.编译

``./Make/Linux/compile Develop``

## 3.更换gc

**替换内容：** 
 
 ```
GameController3/game_controller_net/src/control_message_sender.rs
```
- 发送游戏控制消息到SimRobot (UDP端口3838)

```
GameController3/game_controller_net/src/status_message_receiver.rs
```
- 接收SimRobot机器人状态消息 (UDP端口3939)

```
GameController3/game_controller_msgs/src/control_message.rs
GameController3/game_controller_msgs/src/status_message.rs
```
- 定义与SimRobot通信的RoboCup标准消息格式

```
GameController3/game_controller_msgs/headers/RoboCupGameControlData.h
```
- C语言兼容的协议头文件，与SimRobot接口对接

```
GameController3/game_controller_core/src/actions/
├── penalize.rs          # 惩罚控制
├── goal.rs              # 进球处理  
├── substitute.rs        # 换人操作
└── timeout.rs           # 暂停管理
```
- 游戏动作执行后通过UDP同步到SimRobot

```
GameController3/game_controller_runtime/src/connection_status.rs
```
- 管理与SimRobot的UDP连接状态

```
GameController3/game_controller_app/src/handlers.rs
```
- 处理前端请求，调用UDP通信模块控制SimRobot

```
GameController3/logs/log_2026-01-27_*_*.yaml
```
- 包含SimRobot仿真比赛的实际数据记录

 
**拉取连接：** http://212.64.83.115:5244/ye/gamecontrol


## 4.运行gc

打开gc后需要修改
1.Competition：选择Champions Cup 5 vs. 5
2.队伍暂时只能选择5和70
3.Testing：勾选No Delay
4.**Interface**:lo  （用本地网络）
5.**Casting**:勾选Multicase  （组播）
Start

## 5.打开simrobot
在控制台输入`gc external on`

## 6.观察是否连接所有机器人


