1：拉取代码：git pull
2：上传代码：git add <文件名> （增加全部文件用git add.）
					   git commit -m "增加的内容描述"
					   git push/fecth 
3：git remote -v  				查看远程URL，格式为：仓库名字(默认为origin) +URL（即仓库网络地址）
4：git status 	  -s(可选)					用于查看**查看当前本地仓库的状态**，告诉你：

-   哪些文件提交为空，但是存在尚未跟踪的文件（暂存区没有内容（也就是没有文件被 git add 暂存）

工作区可能有未跟踪文件）
    
-   哪些文件已经暂存准备提交				（add后的文件）
    
-   哪些文件是未跟踪的（新文件）        （新建文件没有add）				
    
-   当前所在分支，以及它和远程分支的差异
- 5：git init  					用来 **在一个文件夹里初始化一个新的 Git 仓库**
- 6：git clone 存在文件丢失问题
	   # 检查项目是否有子模块
		cat .gitmodules  # 查看子模块配置
		#如果文件存在，需要额外步骤：
		git submodule init   # 初始化子模块
		git submodule update --recursive  # 拉取所有子模块
