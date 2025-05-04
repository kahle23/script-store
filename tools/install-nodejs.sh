#!/bin/bash

# 构建目录
mkdir /home/data;
mkdir /home/data/pkg;
mkdir /home/data/tool;



# 下载 nodejs 压缩包
echo "下载 NodeJS 压缩包...";
cd /home/data/pkg;
wget https://nodejs.org/dist/v20.18.1/node-v20.18.1-linux-x64.tar.xz;


# 解压JDK压缩包
echo "解压 NodeJS 压缩包...";
cd /home/data/tool;
tar -xvf /home/data/pkg/node-v20.18.1-linux-x64.tar.xz -C /home/data/tool/;
mv node-v20.18.1-linux-x64/ node20/



# 设置环境变量
echo "设置环境变量...";
echo "
# nodejs
export PATH=\$PATH:/home/data/tool/node20/bin
" >> /etc/profile;


# 使环境变量生效
echo "使环境变量生效...";
source /etc/profile;


# 验证JDK安装
echo "验证 NodeJS 安装...";
node -v;
npm -v;


# 输出JDK安装路径
echo "NodeJS 安装路径：/home/data/tool/node20";







