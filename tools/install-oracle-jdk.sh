#!/bin/bash

# 构建目录
mkdir /home/data;
mkdir /home/data/pkg;
mkdir /home/data/tool;


# 定义变量
# JDK压缩包名称
JDK_PKG="/home/data/pkg/jdk-8u201-linux-x64.tar.gz";
# JDK解压目录
JDK_TAR="/home/data/tool";
# JDK安装目录
JDK_DIR="$JDK_TAR/jdk";


# 检查JDK压缩包是否存在
if [ ! -f "$JDK_PKG" ]; then
    echo "JDK压缩包 $JDK_PKG 不存在，安装结束。"
    exit 1
fi


# 解压JDK压缩包
echo "解压JDK压缩包...";
tar -xvf $JDK_PKG -C $JDK_TAR;


# 设置环境变量
echo "设置环境变量...";
echo "" >> /etc/profile;
echo "# jdk" >> /etc/profile;
echo "export JAVA_HOME=$JDK_DIR" >> /etc/profile;
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile;
echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile;


# 使环境变量生效
echo "使环境变量生效...";
source /etc/profile;


# 验证JDK安装
echo "验证JDK安装...";
java -version;


# 输出JDK安装路径
echo "JDK安装路径：$JDK_DIR";







