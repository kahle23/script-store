#!/bin/bash

# 安装 wget 和 curl
echo "安装基础工具...";
yum -y install wget curl;
yum -y install git;


# 构建目录
echo "创建“gitea”用户...";
useradd gitea;


# 构建目录
echo "创建基础目录...";
mkdir /home/gitea;
sudo -u gitea mkdir /home/gitea/data;


# 构建目录
echo "下载二进制文件...";
cd /home/gitea;
wget https://github.com/go-gitea/gitea/releases/download/v1.22.6/gitea-1.22.6-linux-amd64;




echo "生成启动脚本...";
# 追加内容到文件
echo "#!/bin/bash
# 使用 gitea 用户执行
sudo -u gitea nohup /home/gitea/gitea-1.22.6-linux-amd64 web > /home/gitea/nohup.log 2>&1 &
" >> /home/gitea/startup.sh;
# 设置执行权限
chmod +x /home/gitea/startup.sh;




echo "生成停止脚本...";
# 追加内容到文件
echo "#!/bin/bash

# 要查询的进程名称
PROCESS_NAME=\"gitea-1.22.6-linux-amd64\"

# 使用pgrep查询进程名称匹配的进程号
PID=\$(pgrep -f \$PROCESS_NAME)

# 检查是否找到了进程号
if [ -z \"\$PID\" ]; then
    echo \"进程 \$PROCESS_NAME 没有运行\"
else
    echo \"找到进程 \$PROCESS_NAME，PID为 \$PID\"

    # 发送SIGTERM信号终止进程
    kill \$PID
    # 休眠
    sleep 3.5

    # 检查进程是否成功终止
    if kill -0 \$PID 2>/dev/null; then
        echo \"进程 \$PROCESS_NAME 没有被终止\"
    else
        echo \"进程 \$PROCESS_NAME 已被终止\"
    fi
fi
" >> /home/gitea/stop.sh;
# 设置执行权限
chmod +x /home/gitea/stop.sh;






