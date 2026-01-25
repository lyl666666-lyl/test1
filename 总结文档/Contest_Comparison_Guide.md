# 争球支援功能对照测试指南
# Ball Contest Support Comparison Test Guide

## 测试目的 / Test Purpose

本测试旨在直接对比使用争球支援功能的队伍与使用传统策略的队伍在争球情况下的表现差异。

This test aims to directly compare the performance difference between teams using Ball Contest Support functionality and teams using traditional strategies in ball contest situations.

## 测试设置 / Test Setup

### 队伍配置 / Team Configuration

#### 黑色队 (B-Human) - 使用争球支援功能
- **配置文件**: `Config/BallContestSupport_Enabled.cfg`
- **功能状态**: `enableBallContestSupport = true`
- **预期行为**: 检测争球并派遣支援球员

#### 红色队 (B-Team) - 传统策略
- **配置文件**: `Config/BallContestSupport_Disabled.cfg`
- **功能状态**: `enableBallContestSupport = false`
- **预期行为**: 保持传统的角色分配和位置

### 初始位置 / Initial Positions

```
场地布局 / Field Layout:
                    
红色队门 ←                        → 黑色队门
(-4500,0)                        (4500,0)

Robot25  Robot23  Robot22    Robot2   Robot3   Robot4
  ↑        ↑        ↑         ↑        ↑        ↑
 后卫     中场      前锋      前锋     中场     后卫
Defender  Mid    Forward   Forward   Mid    Defender
 (红)     (红)     (红)      (黑)     (黑)     (黑)

Robot24                Ball                   Robot5
  ↑                     ●                      ↑
 后卫                  (0,0)                  后卫
Defender                                    Defender
 (红)                                        (黑)

Robot21                                     Robot1
  ↑                                           ↑
 门将                                        门将
Keeper                                     Keeper
 (蓝)                                        (紫)
```

## 快速开始 / Quick Start

### 1. 启动对照测试 / Start Comparison Test
```bash
./run_contest_comparison.sh
```

### 2. 手动启动 / Manual Start
```bash
cd Make/Linux
./SimRobot ../../Config/Scenes/ContestComparison.ros3
```

### 3. 加载调试配置 / Load Debug Configuration
在SimRobot中 / In SimRobot:
- `File` -> `Load Configuration`
- 选择 / Select: `Config/Debug/BallContestDebug.cfg`

## 观察要点 / Observation Points

### 1. 争球检测 / Contest Detection

#### 黑色队 (启用支援)
观察控制台输出 / Watch console output:
```
[BallContestProvider] Contest detected between players
[BallContestProvider] Evaluating support candidates...
[BallContestProvider] Robot3 selected for support
```

#### 红色队 (传统策略)
应该没有相关日志输出 / Should have no related log output

### 2. 球员行为对比 / Player Behavior Comparison

| 球员 / Player | 黑色队行为 / Black Team | 红色队行为 / Red Team |
|---------------|------------------------|----------------------|
| 前锋 / Forward | Robot2 参与争球 | Robot22 参与争球 |
| 中场 / Midfielder | Robot3 移动支援 | Robot23 保持位置 |
| 后卫 / Defenders | 保持防守位置 | 保持防守位置 |
| 门将 / Keeper | 保持门前 | 保持门前 |

### 3. 关键指标 / Key Metrics

#### 支援响应时间 / Support Response Time
- **黑色队**: 争球检测后1.5秒内派遣支援
- **红色队**: 无支援响应

#### 球权争夺成功率 / Ball Possession Success Rate
- 观察哪支队伍更频繁地获得球权
- 记录争球持续时间

#### 防守稳定性 / Defensive Stability
- 两队的防守阵型保持情况
- 防守球员的位置变化

## 测试场景 / Test Scenarios

### 场景1: 标准争球 / Standard Contest
**初始状态**: 球在中心，两个前锋接近
**预期结果**:
- 黑色队Robot3移动到支援位置
- 红色队Robot23保持原位置

### 场景2: 手动球移动 / Manual Ball Movement
**操作**: 暂停仿真，移动球到不同位置
**目的**: 测试不同位置的争球支援效果

### 场景3: 长时间观察 / Long-term Observation
**持续时间**: 5-10分钟
**观察**: 多次争球情况下的策略差异

## 性能对比分析 / Performance Comparison Analysis

### 定量指标 / Quantitative Metrics

#### 1. 球权获得次数 / Ball Possession Count
```
测试时间: _____ 分钟
黑色队获得球权: _____ 次
红色队获得球权: _____ 次
成功率差异: _____ %
```

#### 2. 争球持续时间 / Contest Duration
```
平均争球时间:
- 黑色队参与: _____ 秒
- 红色队参与: _____ 秒
```

#### 3. 支援响应统计 / Support Response Statistics
```
争球检测次数: _____
支援派遣次数: _____
支援成功率: _____ %
平均响应时间: _____ 毫秒
```

### 定性观察 / Qualitative Observations

#### 战术优势 / Tactical Advantages
- [ ] 黑色队在争球中表现更积极
- [ ] 支援球员有效提高了球权争夺成功率
- [ ] 防守稳定性得到维持
- [ ] 整体战术协调性良好

#### 潜在问题 / Potential Issues
- [ ] 支援球员离开原位置造成空档
- [ ] 支援响应时间过长
- [ ] 防守风险评估不准确
- [ ] 支援位置选择不当

## 调试和优化 / Debugging and Optimization

### 可视化工具 / Visualization Tools
在SimRobot中启用 / Enable in SimRobot:
- `View` -> `Field` -> `Contest Areas`
- `View` -> `Field` -> `Support Positions`
- `View` -> `Field` -> `Player Roles`

### 参数调整 / Parameter Tuning

#### 如果支援响应太慢 / If Support Response Too Slow
```cfg
# 在 BallContestSupport_Enabled.cfg 中调整
minContestDuration = 1000  # 降低到1秒
```

#### 如果支援过于频繁 / If Support Too Frequent
```cfg
# 在 BallContestSupport_Enabled.cfg 中调整
maxDefensiveRisk = 0.5     # 降低风险阈值
minDefenders = 3           # 增加最少防守球员数
```

#### 如果支援位置不当 / If Support Position Inappropriate
```cfg
# 在 BallContestSupport_Enabled.cfg 中调整
supportDistance = 1200.0   # 调整支援距离
supportPositionWeight = 0.9 # 增加位置权重
```

## 测试结果记录 / Test Results Recording

### 测试信息 / Test Information
```
测试日期: ________________
测试时长: ________________
测试场景: ContestComparison.ros3
SimRobot版本: ________________
```

### 功能验证 / Functionality Verification
- [ ] 黑色队成功检测争球情况
- [ ] 黑色队正确派遣支援球员
- [ ] 红色队保持传统行为
- [ ] 两队防守稳定性良好
- [ ] 无系统错误或崩溃

### 性能对比 / Performance Comparison
```
球权争夺成功率:
- 黑色队: _____%
- 红色队: _____%
- 提升幅度: _____%

平均争球时间:
- 黑色队: _____ 秒
- 红色队: _____ 秒

支援响应时间: _____ 毫秒
```

### 改进建议 / Improvement Suggestions
1. ________________________________
2. ________________________________
3. ________________________________

## 故障排除 / Troubleshooting

### 常见问题 / Common Issues

#### 1. 两队行为相同
**可能原因**: 配置文件未正确加载
**解决方案**: 检查配置文件路径和参数设置

#### 2. 黑色队无支援响应
**可能原因**: enableBallContestSupport参数未生效
**解决方案**: 重新构建项目并检查参数加载

#### 3. 红色队也有支援行为
**可能原因**: 配置文件混淆
**解决方案**: 确认红色队使用Disabled配置

#### 4. 仿真性能问题
**可能原因**: 调试输出过多
**解决方案**: 在非调试模式下运行测试

## 总结 / Summary

通过这个对照测试，你可以：

1. **直观对比**: 清楚看到两种策略的差异
2. **量化评估**: 获得具体的性能数据
3. **验证功能**: 确认争球支援功能正常工作
4. **优化参数**: 基于测试结果调整配置
5. **战术分析**: 理解新功能的战术价值

这个测试为争球支援功能提供了科学的验证方法，确保新功能确实能够提升团队在争球情况下的表现。

---

**准备开始测试！Ready to start testing!**

运行 `./run_contest_comparison.sh` 开始你的对照测试。