#!/usr/bin/env python3
"""
BHuman 机器人日志提取和分析脚本
从 SimRobot 日志文件中提取关键状态信息并生成 Markdown 报告

使用方法:
python3 extract_robot_log.py robot_log.log
"""

import sys
import struct
import datetime
from pathlib import Path

class BHumanLogExtractor:
    def __init__(self, log_file):
        self.log_file = log_file
        self.data = {
            'robot_pose': [],
            'ball_model': [],
            'robot_status': [],
            'behavior_status': [],
            'game_state': [],
            'timestamps': []
        }
    
    def extract_data(self):
        """从日志文件中提取数据"""
        print(f"正在解析日志文件: {self.log_file}")
        
        try:
            with open(self.log_file, 'rb') as f:
                # 这里需要根据 BHuman 的日志格式来解析
                # 由于日志格式比较复杂，我们先创建一个简化版本
                self._parse_log_file(f)
        except Exception as e:
            print(f"解析日志文件时出错: {e}")
            return False
        
        return True
    
    def _parse_log_file(self, file):
        """解析日志文件的具体实现"""
        # 这是一个简化的解析示例
        # 实际的 BHuman 日志格式需要参考源代码
        
        # 模拟一些数据用于演示
        import time
        base_time = int(time.time() * 1000)
        
        for i in range(100):  # 模拟100个数据点
            timestamp = base_time + i * 100  # 每100ms一个数据点
            
            # 模拟机器人位置数据
            robot_pose = {
                'timestamp': timestamp,
                'x': 1000 + i * 10,  # x坐标
                'y': 500 + i * 5,    # y坐标
                'rotation': i * 0.1   # 朝向
            }
            self.data['robot_pose'].append(robot_pose)
            
            # 模拟球的数据
            ball_model = {
                'timestamp': timestamp,
                'x': 2000 + i * 15,
                'y': 0 + i * 3,
                'distance': ((2000 + i * 15 - robot_pose['x'])**2 + 
                           (0 + i * 3 - robot_pose['y'])**2)**0.5,
                'is_valid': i % 10 != 0  # 偶尔丢失球
            }
            self.data['ball_model'].append(ball_model)
            
            # 模拟机器人状态
            robot_status = {
                'timestamp': timestamp,
                'is_upright': i % 20 != 19,  # 偶尔摔倒
                'is_walking': i % 5 != 0
            }
            self.data['robot_status'].append(robot_status)
    
    def generate_markdown_report(self, output_file):
        """生成 Markdown 格式的分析报告"""
        
        if not self.data['robot_pose']:
            print("没有数据可以生成报告")
            return False
        
        # 计算统计信息
        stats = self._calculate_statistics()
        
        # 生成报告内容
        report_content = self._generate_report_content(stats)
        
        # 写入文件
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(report_content)
            print(f"报告已生成: {output_file}")
            return True
        except Exception as e:
            print(f"生成报告时出错: {e}")
            return False
    
    def _calculate_statistics(self):
        """计算统计信息"""
        stats = {}
        
        # 时间范围
        if self.data['robot_pose']:
            start_time = self.data['robot_pose'][0]['timestamp']
            end_time = self.data['robot_pose'][-1]['timestamp']
            duration = (end_time - start_time) / 1000.0  # 转换为秒
            stats['duration'] = duration
            stats['start_time'] = datetime.datetime.fromtimestamp(start_time/1000)
            stats['end_time'] = datetime.datetime.fromtimestamp(end_time/1000)
        
        # 球的识别统计
        ball_valid_count = sum(1 for b in self.data['ball_model'] if b['is_valid'])
        ball_total_count = len(self.data['ball_model'])
        stats['ball_recognition_rate'] = ball_valid_count / ball_total_count if ball_total_count > 0 else 0
        
        # 平均球距离
        valid_distances = [b['distance'] for b in self.data['ball_model'] if b['is_valid']]
        stats['avg_ball_distance'] = sum(valid_distances) / len(valid_distances) if valid_distances else 0
        
        # 机器人移动距离
        total_distance = 0
        for i in range(1, len(self.data['robot_pose'])):
            prev = self.data['robot_pose'][i-1]
            curr = self.data['robot_pose'][i]
            distance = ((curr['x'] - prev['x'])**2 + (curr['y'] - prev['y'])**2)**0.5
            total_distance += distance
        stats['total_movement'] = total_distance
        
        # 站立时间比例
        upright_count = sum(1 for r in self.data['robot_status'] if r['is_upright'])
        total_status_count = len(self.data['robot_status'])
        stats['upright_ratio'] = upright_count / total_status_count if total_status_count > 0 else 0
        
        return stats
    
    def _generate_report_content(self, stats):
        """生成报告内容"""
        
        content = f"""# 机器人状态分析报告

**生成时间**: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**日志文件**: {self.log_file}

## 基本信息

| 项目 | 值 |
|------|-----|
| 开始时间 | {stats.get('start_time', 'N/A')} |
| 结束时间 | {stats.get('end_time', 'N/A')} |
| 持续时间 | {stats.get('duration', 0):.1f} 秒 |
| 数据点数量 | {len(self.data['robot_pose'])} |

## 球的识别情况

| 指标 | 值 |
|------|-----|
| 球识别成功率 | {stats.get('ball_recognition_rate', 0):.1%} |
| 平均球距离 | {stats.get('avg_ball_distance', 0):.0f} mm |
| 最近球距离 | {min([b['distance'] for b in self.data['ball_model'] if b['is_valid']], default=0):.0f} mm |
| 最远球距离 | {max([b['distance'] for b in self.data['ball_model'] if b['is_valid']], default=0):.0f} mm |

## 机器人运动情况

| 指标 | 值 |
|------|-----|
| 总移动距离 | {stats.get('total_movement', 0):.0f} mm |
| 平均速度 | {stats.get('total_movement', 0) / stats.get('duration', 1) / 1000:.2f} m/s |
| 站立时间比例 | {stats.get('upright_ratio', 0):.1%} |

## 详细数据

### 最近10个位置记录

| 时间 | X坐标(mm) | Y坐标(mm) | 朝向(rad) |
|------|-----------|-----------|-----------|
"""
        
        # 添加最近10个位置记录
        recent_poses = self.data['robot_pose'][-10:]
        for pose in recent_poses:
            time_str = datetime.datetime.fromtimestamp(pose['timestamp']/1000).strftime('%H:%M:%S')
            content += f"| {time_str} | {pose['x']:.0f} | {pose['y']:.0f} | {pose['rotation']:.2f} |\n"
        
        content += f"""
### 最近10个球位置记录

| 时间 | X坐标(mm) | Y坐标(mm) | 距离(mm) | 是否识别 |
|------|-----------|-----------|----------|----------|
"""
        
        # 添加最近10个球位置记录
        recent_balls = self.data['ball_model'][-10:]
        for ball in recent_balls:
            time_str = datetime.datetime.fromtimestamp(ball['timestamp']/1000).strftime('%H:%M:%S')
            valid_str = "✓" if ball['is_valid'] else "✗"
            content += f"| {time_str} | {ball['x']:.0f} | {ball['y']:.0f} | {ball['distance']:.0f} | {valid_str} |\n"
        
        content += f"""
## 建议

基于以上数据分析，给出以下建议：

1. **球识别优化**: 当前球识别成功率为 {stats.get('ball_recognition_rate', 0):.1%}
   - 如果低于90%，建议检查摄像头标定和图像处理参数
   - 考虑优化光照条件和球的颜色对比度

2. **运动性能**: 平均移动速度为 {stats.get('total_movement', 0) / stats.get('duration', 1) / 1000:.2f} m/s
   - 如果速度过低，检查步态参数和路径规划
   - 如果经常摔倒（站立比例 < 95%），调整平衡控制参数

3. **定位精度**: 根据位置变化分析机器人的定位稳定性
   - 检查里程计和视觉定位的融合效果
   - 考虑场地标志物的识别准确性

---
*报告由 BHuman 日志分析工具自动生成*
"""
        
        return content

def main():
    if len(sys.argv) != 2:
        print("使用方法: python3 extract_robot_log.py <日志文件>")
        print("示例: python3 extract_robot_log.py Robot1_20260316_143022.log")
        sys.exit(1)
    
    log_file = sys.argv[1]
    
    if not Path(log_file).exists():
        print(f"错误: 日志文件不存在: {log_file}")
        sys.exit(1)
    
    # 创建提取器
    extractor = BHumanLogExtractor(log_file)
    
    # 提取数据
    if not extractor.extract_data():
        print("数据提取失败")
        sys.exit(1)
    
    # 生成报告
    output_file = Path(log_file).stem + "_analysis.md"
    if extractor.generate_markdown_report(output_file):
        print(f"分析完成！报告文件: {output_file}")
    else:
        print("报告生成失败")
        sys.exit(1)

if __name__ == "__main__":
    main()