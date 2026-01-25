# SimRobot Ball Contest Support Testing Guide
# SimRobot 争球支援测试指南

## 测试环境设置

### 1. 启动SimRobot

#### 选项A: 专用测试场景 (推荐用于功能验证)
```bash
cd Make/Linux
./SimRobot ../../Config/Scenes/BallContestTest.ros2
```

#### 选项B: GameFast仿真 (推荐用于实际比赛测试)
```bash
cd Make/Linux
./SimRobot ../../Config/Scenes/GameFast.ros3
```

#### 选项C: 增强GameFast场景 (包含争球场景设置)
```bash
cd Make/Linux
./SimRobot ../../Config/Scenes/GameFastBallContest.ros3
```

#### 选项D: 使用便捷脚本
```bash
# 运行标准GameFast仿真
./run_gamefast_contest.sh

# 或运行测试助手
./test_gamefast_contest.sh
```

### 2. 加载调试配置
在SimRobot中：
1. 打开 `File` -> `Load Configuration`
2. 选择 `Config/Debug/BallContestDebug.cfg`
3. 确认调试模式已启用

## GameFast仿真中的测试

### GameFast场景特点
- **完整5v5比赛环境**: 真实的比赛场景和机器人配置
- **动态争球情况**: 在比赛过程中自然发生的争球
- **完整策略集成**: BallContestSupport与其他策略模块的协同工作
- **性能测试**: 在复杂环境中的实时性能验证

### GameFast测试步骤

#### 步骤1: 启动GameFast仿真
1. 运行 `./run_gamefast_contest.sh` 或手动启动
2. 加载调试配置 `Config/Debug/BallContestDebug.cfg`
3. 观察初始机器人位置和球的位置

#### 步骤2: 创建争球场景
在GameFast中，争球情况会在以下时机自然发生：
- 开球后球员接近球时
- 中场争抢时
- 边线球或角球后
- 防守反击转换时

**手动创建争球场景**:
1. 暂停仿真 (Space键)
2. 将球移动到两个对手球员之间
3. 恢复仿真观察争球检测和支援响应

#### 步骤3: 观察支援行为
在GameFast环境中观察：
- 争球检测的准确性和及时性
- 支援球员选择的合理性
- 支援位置计算的有效性
- 与其他策略的协调性
- 防守阵型的维持

#### 步骤4: 性能验证
监控GameFast中的性能指标：
- 争球检测延迟 < 100ms
- 支援决策时间 < 200ms
- 位置计算时间 < 50ms
- 整体帧率保持稳定

### GameFast vs 专用测试场景对比

| 特性 | BallContestTest.ros2 | GameFast.ros3 |
|------|---------------------|---------------|
| 测试目的 | 功能验证 | 实战测试 |
| 场景复杂度 | 简单，专注争球 | 复杂，完整比赛 |
| 测试控制 | 高度可控 | 动态变化 |
| 性能要求 | 中等 | 高 |
| 调试便利性 | 高 | 中等 |
| 实战相关性 | 中等 | 高 |

**建议测试流程**:
1. 首先在BallContestTest.ros2中验证基础功能
2. 然后在GameFast.ros3中测试实战表现
3. 最后在GameFastBallContest.ros3中进行压力测试

### 初始设置
- **Robot2 (黑色)**: 位于 (500, 200)，争球球员
- **Robot22 (红色)**: 位于 (600, 100)，对手争球球员  
- **Ball**: 位于 (550, 150)，两个球员之间
- **Robot3 (黑色)**: 位于 (0, 500)，潜在支援球员
- **其他球员**: 分布在场地各位置

### 预期行为
1. 系统检测到Robot2和Robot22的争球情况
2. 评估防守风险（应该在可接受范围内）
3. 选择Robot3作为最佳支援候选
4. Robot3移动到计算出的支援位置
5. 其他球员保持当前角色和位置

## 测试步骤

### 步骤1: 基础争球检测
1. 启动仿真
2. 观察Console输出中的争球检测日志
3. 验证系统是否正确识别争球情况

**预期结果**:
```
[BallContestProvider] Contest detected between players 2 and 22
[BallContestProvider] Contest intensity: 0.85
[BallContestProvider] Contest duration: 1500ms
```

### 步骤2: 支援决策验证
1. 等待争球持续超过最小时间阈值
2. 观察支援决策日志
3. 验证Robot3被选为支援球员

**预期结果**:
```
[BallContestProvider] Evaluating support candidates...
[BallContestProvider] Robot3 score: 0.75 (distance: 0.6, position: 0.8, availability: 1.0)
[BallContestProvider] Assigning support role to Robot3
```

### 步骤3: 位置计算测试
1. 观察Robot3的移动轨迹
2. 验证支援位置是否合理
3. 检查位置是否在场地边界内

**预期支援位置**: 大约在 (200, 400) 附近

### 步骤4: 防守风险评估
1. 观察防守风险计算日志
2. 验证风险值在可接受范围内
3. 确认没有过多球员离开防守位置

**预期结果**:
```
[BallContestProvider] Defensive risk: 0.4 (acceptable)
[BallContestProvider] Defenders in own half: 3/5
```

## 调试工具使用

### 1. 可视化调试
在SimRobot中启用以下视图：
- `View` -> `Field` -> `Contest Areas`
- `View` -> `Field` -> `Support Positions`
- `View` -> `Field` -> `Player Roles`

### 2. 数据监控
监控以下数据流：
- `BallContestStatus`
- `AgentStates`
- `StrategyStatus`

### 3. 日志分析
关键日志文件：
- `Logs/BallContestProvider.log`
- `Logs/BehaviorControl.log`
- `Logs/StrategyBehaviorControl.log`

## 测试变体

### 变体1: 高风险场景
修改机器人位置，使更多球员在前场：
```xml
<!-- 将Robot4和Robot5移动到前场 -->
<Translation x="1000" y="-500" z="320mm"/>
<Translation x="800" y="300" z="320mm"/>
```

**预期**: 系统应该拒绝派遣支援（防守风险过高）

### 变体2: 多候选场景
添加更多潜在支援球员：
```xml
<!-- 添加额外的机器人在合适位置 -->
<Body ref="Nao" name="robot6">
  <Translation x="200" y="-400" z="320mm"/>
  <Set name="TeamColor" value="black"/>
</Body>
```

**预期**: 系统选择最佳候选（距离和位置综合评分最高）

### 变体3: 争球结束场景
在测试过程中移动球：
1. 暂停仿真
2. 手动移动球到远离争球区域
3. 恢复仿真

**预期**: Robot3应该停止支援并返回原位置

## 性能测试

### 1. 执行时间测试
监控关键函数的执行时间：
- `BallContestProvider::update()` < 5ms
- `BallContestSupport::execute()` < 3ms
- `assignBallContestSupport()` < 2ms

### 2. 内存使用测试
监控内存使用情况，确保没有内存泄漏

### 3. 通信延迟测试
模拟网络延迟，验证系统鲁棒性

## 故障排除

### 常见问题

#### 1. 争球未被检测
**可能原因**:
- 球员距离球太远
- 争球持续时间不足
- 球移动速度过快

**解决方案**:
- 调整 `contestDetectionRadius`
- 降低 `minContestDuration`
- 检查球的速度阈值

#### 2. 支援未被派遣
**可能原因**:
- 防守风险过高
- 没有合适的候选球员
- 支援得分低于阈值

**解决方案**:
- 提高 `maxDefensiveRisk`
- 调整候选球员位置
- 降低 `minSupportScore`

#### 3. 支援位置不合理
**可能原因**:
- 位置计算算法问题
- 场地边界限制
- 参数设置不当

**解决方案**:
- 检查 `calculateSupportPosition()` 实现
- 调整 `supportDistance` 参数
- 验证场地尺寸设置

### 调试命令

在SimRobot Console中使用：
```
# 启用详细日志
set debug BallContestProvider true

# 显示争球状态
get BallContestStatus

# 手动触发支援
call assignBallContestSupport

# 重置测试场景
reset BallContestTest
```

## 测试报告模板

### 测试结果记录
```
测试日期: ____
测试场景: BallContestTest.ros2
测试版本: ____

争球检测:
- 检测成功: [ ] 是 [ ] 否
- 检测延迟: ____ms
- 误检次数: ____

支援决策:
- 正确选择支援球员: [ ] 是 [ ] 否
- 决策时间: ____ms
- 防守风险评估: ____

位置计算:
- 支援位置合理: [ ] 是 [ ] 否
- 位置精度: ____mm
- 边界检查: [ ] 通过 [ ] 失败

性能指标:
- 平均执行时间: ____ms
- 最大执行时间: ____ms
- 内存使用: ____MB

问题记录:
1. ________________
2. ________________
3. ________________

改进建议:
1. ________________
2. ________________
3. ________________
```

## 下一步测试

1. **实机测试**: 在真实NAO机器人上验证
2. **对抗测试**: 与其他团队策略对比
3. **长期测试**: 验证系统稳定性
4. **压力测试**: 极端场景下的表现

通过这个全面的测试指南，你可以系统地验证争球支援策略的各个方面，确保实现的正确性和可靠性。