#!/bin/bash

# 安装 wget 和 curl
echo "安装基础工具...";
yum -y install wget curl;


# 构建目录
echo "创建基础目录...";
mkdir /home/data/tool/jpom-agent;



# 构建目录
echo "下载二进制文件...";
cd /home/data/tool/jpom-agent;
wget https://d.jpom.download/release/2.11.11/agent-2.11.11-release.tar.gz;


# 构建目录
echo "解压...";
tar -zxf agent-2.11.11-release.tar.gz;
rm -rf agent-2.11.11-release.tar.gz;



echo "生成自述...";
# 追加内容到文件
echo "
sh bin/Agent.sh start
sh bin/Agent.sh stop
sh bin/Agent.sh restart
sh bin/Agent.sh status
" >> /home/data/tool/jpom-agent/readme.txt;






