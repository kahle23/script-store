#!/bin/bash

# 构建目录
mkdir /home/data;
mkdir /home/data/pkg;
mkdir /home/data/tool;
mkdir /home/data/tool/maven-repository;


# 下载 Maven 压缩包
echo "下载 Maven 压缩包...";
cd /home/data/pkg;
wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz;


# 解压JDK压缩包
echo "解压 Maven 压缩包...";
cd /home/data/tool;
tar -xvf /home/data/pkg/apache-maven-3.6.3-bin.tar.gz -C /home/data/tool/;
mv apache-maven-3.6.3/ maven3/


# 解压JDK压缩包
echo "备份 Maven 配置文件...";
cp /home/data/tool/maven3/conf/settings.xml /home/data/tool/maven3/conf/settings.xml.bak



# 设置环境变量
echo "设置环境变量...";
echo "
# maven
export M2_HOME=/home/data/tool/maven3
export M2=\$M2_HOME/bin
export PATH=\$M2:\$PATH
" >> /etc/profile;


# 使环境变量生效
echo "使环境变量生效...";
source /etc/profile;


# 验证JDK安装
echo "验证 Maven 安装...";
mvn -version;


# 输出JDK安装路径
echo "Maven安装路径：/home/data/tool/maven3";







