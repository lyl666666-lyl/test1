#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
为每个队伍创建独立的可双击打开的日志查看器
这个HTML文件会内嵌所有日志数据，可以直接双击打开
"""

import os
import json
import glob
from pathlib import Path

def create_standalone_viewer(team_dir, team_name):
    """为指定队伍创建独立查看器"""
    
    # 查找所有日志文件
    log_files = sorted(glob.glob(os.path.join(team_dir, "team_comm_p*.txt")))
    
    if not log_files:
        return False
    
    # 读取所有日志文件内容
    logs_data = []
    for log_file in log_files:
        filename = os.path.basename(log_file)
        try:
            with open(log_file, 'r', encoding='utf-8') as f:
                content = f.read()
                logs_data.append({
                    "filename": filename,
                    "content": content
                })
        except Exception as e:
            print(f"    ⚠️  无法读取 {filename}: {e}")
            continue
    
    if not logs_data:
        return False
    
    # 将日志数据转换为JSON字符串
    logs_json = json.dumps(logs_data, ensure_ascii=False)
    
    # HTML模板
    html_template = '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{team_name} - 团队通信日志查看器</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }}
        .container {{
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }}
        .header h1 {{ font-size: 2.5em; margin-bottom: 10px; }}
        .header p {{ font-size: 1.1em; opacity: 0.9; }}
        .controls {{
            padding: 25px;
            background: #f8f9fa;
            border-bottom: 2px solid #e9ecef;
        }}
        .control-group {{ margin-bottom: 15px; }}
        .control-group label {{
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #495057;
        }}
        .filter-bar {{
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }}
        .filter-bar input, .filter-bar select {{
            flex: 1;
            min-width: 200px;
            padding: 10px 15px;
            border: 2px solid #dee2e6;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }}
        .filter-bar input:focus, .filter-bar select:focus {{
            outline: none;
            border-color: #667eea;
        }}
        .stats {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            padding: 25px;
            background: #f8f9fa;
        }}
        .stat-card {{
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s;
        }}
        .stat-card:hover {{ transform: translateY(-5px); }}
        .stat-card .value {{
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 5px;
        }}
        .stat-card .label {{ color: #6c757d; font-size: 0.9em; }}
        .content {{ padding: 25px; max-height: 70vh; overflow-y: auto; }}
        .log-entry {{
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 15px;
            transition: all 0.3s;
        }}
        .log-entry:hover {{
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            border-color: #667eea;
        }}
        .log-entry.send {{ border-left: 5px solid #28a745; }}
        .log-entry.receive {{ border-left: 5px solid #007bff; }}
        .log-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid #e9ecef;
        }}
        .log-type {{
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 0.9em;
        }}
        .log-type.send {{ background: #28a745; color: white; }}
        .log-type.receive {{ background: #007bff; color: white; }}
        .log-time {{ color: #6c757d; font-size: 0.9em; }}
        .log-details {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }}
        .detail-item {{
            background: #f8f9fa;
            padding: 12px;
            border-radius: 8px;
        }}
        .detail-item .detail-label {{
            font-weight: 600;
            color: #495057;
            margin-bottom: 5px;
            font-size: 0.85em;
        }}
        .detail-item .detail-value {{ color: #212529; font-size: 1em; }}
        .no-data {{
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }}
        .badge {{
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.75em;
            font-weight: 600;
            background: #28a745;
            color: white;
            margin-left: 10px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 {team_name} 团队通信日志</h1>
            <p>📁 独立查看器 - 可直接双击打开 <span class="badge">✓ 离线可用</span></p>
        </div>
        
        <div class="controls">
            <div class="control-group">
                <label>🔍 筛选条件</label>
                <div class="filter-bar">
                    <input type="text" id="searchInput" placeholder="搜索关键词...">
                    <select id="typeFilter">
                        <option value="all">全部类型</option>
                        <option value="send">仅发送</option>
                        <option value="receive">仅接收</option>
                    </select>
                    <select id="robotFilter">
                        <option value="all">全部机器人</option>
                    </select>
                </div>
            </div>
        </div>
        
        <div class="stats" id="stats">
            <div class="stat-card">
                <div class="value" id="totalMessages">0</div>
                <div class="label">总消息数</div>
            </div>
            <div class="stat-card">
                <div class="value" id="sendMessages">0</div>
                <div class="label">发送消息</div>
            </div>
            <div class="stat-card">
                <div class="value" id="receiveMessages">0</div>
                <div class="label">接收消息</div>
            </div>
            <div class="stat-card">
                <div class="value" id="robotCount">0</div>
                <div class="label">机器人数量</div>
            </div>
        </div>
        
        <div class="content" id="content">
            <div class="no-data">
                <div style="font-size: 4em; margin-bottom: 20px;">⏳</div>
                <h3>正在加载日志...</h3>
            </div>
        </div>
    </div>

    <script>
        // 内嵌的日志数据
        const embeddedLogs = {logs_json};
        
        let allLogs = [];
        let filteredLogs = [];

        document.getElementById('searchInput').addEventListener('input', applyFilters);
        document.getElementById('typeFilter').addEventListener('change', applyFilters);
        document.getElementById('robotFilter').addEventListener('change', applyFilters);

        function loadEmbeddedLogs() {{
            console.log('开始加载日志...');
            console.log('embeddedLogs数量:', embeddedLogs.length);
            embeddedLogs.forEach(logFile => {{
                console.log('处理文件:', logFile.filename, '长度:', logFile.content.length);
                parseLogs(logFile.content, logFile.filename);
            }});
            console.log('解析完成，总日志数:', allLogs.length);
            updateRobotFilter();
            applyFilters();
            updateStats();
        }}

        function parseLogs(content, filename) {{
            console.log(`解析 ${{filename}}, 内容长度: ${{content.length}}`);
            const lines = content.split('\\n');
            console.log(`  分割后行数: ${{lines.length}}`);
            let currentLog = null;
            let matchCount = 0;
            
            for (let line of lines) {{
                line = line.trim();
                
                if (line.startsWith('[发送]') || line.startsWith('[接收]')) {{
                    matchCount++;
                    if (currentLog) {{
                        allLogs.push(currentLog);
                    }}
                    
                    const type = line.startsWith('[发送]') ? 'send' : 'receive';
                    const timeMatch = line.match(/时间=(\\d+)ms/);
                    const robotMatch = line.match(/来自机器人(\\d+)号/) || line.match(/机器人: (\\d+)号/);
                    
                    currentLog = {{
                        type: type,
                        time: timeMatch ? parseInt(timeMatch[1]) : 0,
                        robot: robotMatch ? parseInt(robotMatch[1]) : null,
                        filename: filename,
                        details: {{}}
                    }};
                }} else if (currentLog && line) {{
                    if (line.includes('位置:')) {{
                        currentLog.details.position = line.replace('位置:', '').trim();
                    }} else if (line.includes('球:')) {{
                        currentLog.details.ball = line.replace('球:', '').trim();
                    }} else if (line.includes('角色:')) {{
                        currentLog.details.role = line.replace('角色:', '').trim();
                    }} else if (line.includes('传球目标:')) {{
                        currentLog.details.pass = line.replace('传球目标:', '').trim();
                    }} else if (line.includes('消息预算剩余:')) {{
                        currentLog.details.budget = line.replace('消息预算剩余:', '').trim();
                    }}
                }}
            }}
            
            if (currentLog) {{
                allLogs.push(currentLog);
            }}
            console.log(`  找到 ${{matchCount}} 个日志条目`);
        }}

        function updateRobotFilter() {{
            const robots = new Set();
            allLogs.forEach(log => {{
                if (log.robot) robots.add(log.robot);
            }});
            
            const select = document.getElementById('robotFilter');
            select.innerHTML = '<option value="all">全部机器人</option>';
            
            Array.from(robots).sort((a, b) => a - b).forEach(robot => {{
                const option = document.createElement('option');
                option.value = robot;
                option.textContent = `机器人 ${{robot}} 号`;
                select.appendChild(option);
            }});
        }}

        function applyFilters() {{
            const searchTerm = document.getElementById('searchInput').value.toLowerCase();
            const typeFilter = document.getElementById('typeFilter').value;
            const robotFilter = document.getElementById('robotFilter').value;
            
            filteredLogs = allLogs.filter(log => {{
                if (typeFilter !== 'all' && log.type !== typeFilter) return false;
                if (robotFilter !== 'all' && log.robot !== parseInt(robotFilter)) return false;
                if (searchTerm) {{
                    const searchableText = JSON.stringify(log).toLowerCase();
                    if (!searchableText.includes(searchTerm)) return false;
                }}
                return true;
            }});
            
            renderLogs();
        }}

        function renderLogs() {{
            const content = document.getElementById('content');
            
            if (filteredLogs.length === 0) {{
                content.innerHTML = `
                    <div class="no-data">
                        <div style="font-size: 4em; margin-bottom: 20px;">🔍</div>
                        <h3>没有找到匹配的日志</h3>
                        <p style="margin-top: 10px;">尝试调整筛选条件</p>
                    </div>
                `;
                return;
            }}
            
            content.innerHTML = filteredLogs.map(log => `
                <div class="log-entry ${{log.type}}">
                    <div class="log-header">
                        <span class="log-type ${{log.type}}">
                            ${{log.type === 'send' ? '📤 发送' : '📥 接收'}}
                            ${{log.robot ? ` - 机器人 ${{log.robot}} 号` : ''}}
                        </span>
                        <span class="log-time">⏱️ ${{log.time}}ms</span>
                    </div>
                    <div class="log-details">
                        ${{log.details.position ? `
                            <div class="detail-item">
                                <div class="detail-label">📍 位置</div>
                                <div class="detail-value">${{log.details.position}}</div>
                            </div>
                        ` : ''}}
                        ${{log.details.ball ? `
                            <div class="detail-item">
                                <div class="detail-label">⚽ 球位置</div>
                                <div class="detail-value">${{log.details.ball}}</div>
                            </div>
                        ` : ''}}
                        ${{log.details.role ? `
                            <div class="detail-item">
                                <div class="detail-label">👤 角色</div>
                                <div class="detail-value">${{log.details.role}}</div>
                            </div>
                        ` : ''}}
                        ${{log.details.pass ? `
                            <div class="detail-item">
                                <div class="detail-label">🎯 传球/行走</div>
                                <div class="detail-value">${{log.details.pass}}</div>
                            </div>
                        ` : ''}}
                        ${{log.details.budget ? `
                            <div class="detail-item">
                                <div class="detail-label">💰 消息预算</div>
                                <div class="detail-value">${{log.details.budget}}</div>
                            </div>
                        ` : ''}}
                    </div>
                </div>
            `).join('');
        }}

        function updateStats() {{
            const sendCount = allLogs.filter(log => log.type === 'send').length;
            const receiveCount = allLogs.filter(log => log.type === 'receive').length;
            const robots = new Set(allLogs.map(log => log.robot).filter(r => r));
            
            document.getElementById('totalMessages').textContent = allLogs.length;
            document.getElementById('sendMessages').textContent = sendCount;
            document.getElementById('receiveMessages').textContent = receiveCount;
            document.getElementById('robotCount').textContent = robots.size;
        }}

        // 页面加载时自动加载内嵌的日志
        loadEmbeddedLogs();
    </script>
</body>
</html>'''
    
    # 生成HTML内容
    html_content = html_template.format(
        team_name=team_name,
        logs_json=logs_json
    )
    
    # 写入HTML文件
    html_path = os.path.join(team_dir, "view_logs_standalone.html")
    try:
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        return True
    except Exception as e:
        print(f"    ❌ 无法写入HTML文件: {e}")
        return False

def main():
    """主函数"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sim_logs_dir = os.path.join(script_dir, "Config", "Sim_Logs")
    
    if not os.path.exists(sim_logs_dir):
        print(f"❌ 日志目录不存在: {sim_logs_dir}")
        return
    
    print("🔍 扫描日志目录...")
    
    # 遍历所有比赛时间戳目录
    match_dirs = sorted([d for d in glob.glob(os.path.join(sim_logs_dir, "*")) if os.path.isdir(d)])
    
    for match_dir in match_dirs:
        match_name = os.path.basename(match_dir)
        print(f"\n📂 比赛: {match_name}")
        
        # 遍历每个队伍目录
        team_dirs = sorted([d for d in glob.glob(os.path.join(match_dir, "*")) if os.path.isdir(d)])
        
        for team_dir in team_dirs:
            team_name = os.path.basename(team_dir)
            
            # 检查是否有日志文件
            log_files = glob.glob(os.path.join(team_dir, "team_comm_p*.txt"))
            if not log_files:
                print(f"  ⊘ {team_name} - 没有日志文件")
                continue
            
            print(f"  ⚙️  {team_name} - 生成独立查看器...")
            
            if create_standalone_viewer(team_dir, team_name):
                print(f"  ✅ {team_name} - 独立查看器生成完成: view_logs_standalone.html")
            else:
                print(f"  ❌ {team_name} - 生成失败")
    
    print("\n✅ 所有独立查看器生成完成！")
    print("\n💡 使用方法：")
    print("   直接双击 view_logs_standalone.html 文件即可打开")
    print("   无需启动HTTP服务器，可离线使用")

if __name__ == "__main__":
    main()
