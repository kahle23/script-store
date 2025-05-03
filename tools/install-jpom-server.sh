#!/bin/bash

# 安装 wget 和 curl
echo "安装基础工具...";
yum -y install wget curl;
yum -y install git;


# 构建目录
echo "创建基础目录...";
mkdir /home/data/tool/jpom-server;



# 构建目录
echo "下载二进制文件...";
cd /home/data/tool/jpom-server;
wget https://d.jpom.download/release/2.11.11/server-2.11.11-release.tar.gz;


# 构建目录
echo "解压...";
tar -zxf server-2.11.11-release.tar.gz;
rm -rf server-2.11.11-release.tar.gz;



echo "生成自述...";
# 追加内容到文件
echo "
sh bin/Server.sh start
sh bin/Server.sh stop
sh bin/Server.sh restart
sh bin/Server.sh status
" >> /home/data/tool/jpom-server/readme.txt;






