#!/bin/bash

hostname="$1";

# 检查是否传入了主机名参数
if [ -n "$hostname" ]; then
    hostnamectl set-hostname "$hostname"
fi


# 设置时区为上海
timedatectl set-timezone Asia/Shanghai;



# 安装 EPEL 仓库
yum -y install epel-release;
# 安装 lrzsz
yum -y install lrzsz;
# 安装 htop
yum -y install htop;
# 安装 net-tools
yum -y install net-tools;
# 安装 bind-utils
yum -y install bind-utils;
# 安装 zip 、 unzip 和 tar
yum -y install zip unzip tar;
# 安装 wget 和 curl
yum -y install wget curl;




# 总的数据文件夹
mkdir /home/data;
# 工具文件夹
mkdir /home/data/tool;
# 安装包文件夹
mkdir /home/data/pkg;
# 后端服务文件夹
mkdir /home/data/app;
# 前端项目文件夹
mkdir /home/data/web;




# 关闭防火墙
systemctl stop firewalld;
systemctl disable firewalld;








