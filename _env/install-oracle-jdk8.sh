#!/bin/bash
# ==================================================
# JDK 自动安装脚本
# [功能]：检查并自动下载安装 JDK（修改路径直接改脚本把）
# [用法]：./install-oracle-jdk8.sh
# ==================================================


# 遇到错误立即退出
set -e

# 定义变量
JDK_DOWNLOAD_URL="https://download.oracle.com/otn/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz"
JDK_PKG_DIR="/opt/pkg/jdk"
JDK_PKG_NAME="jdk-8u201-linux-x64.tar.gz"
JDK_PKG="$JDK_PKG_DIR/$JDK_PKG_NAME"
JDK_MAIN_DIR="/opt/jdk"
JDK_DIR="$JDK_MAIN_DIR/jdk8"


# 创建必要的目录
mkdir -p "$JDK_PKG_DIR"
mkdir -p "$JDK_MAIN_DIR"


# 检查并下载JDK压缩包
if [ ! -f "$JDK_PKG" ]; then
    echo "JDK压缩包不存在，开始下载..."

    # 检查是否支持下载工具
    if command -v wget &> /dev/null; then
        echo "使用 wget 下载JDK..."
        if ! wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -O "$JDK_PKG" "$JDK_DOWNLOAD_URL"; then
            echo "下载失败，请检查网络连接或URL有效性"
            exit 1
        fi
    elif command -v curl &> /dev/null; then
        echo "使用 curl 下载JDK..."
        if ! curl -L -b "oraclelicense=accept-securebackup-cookie" -o "$JDK_PKG" "$JDK_DOWNLOAD_URL"; then
            echo "下载失败，请检查网络连接或URL有效性"
            exit 1
        fi
    else
        echo "错误: 没有找到 wget 或 curl，无法下载JDK"
        echo "请手动下载JDK并放置在: $JDK_PKG"
        echo "下载URL: $JDK_DOWNLOAD_URL"
        exit 1
    fi

    # 验证下载文件
    if [ ! -f "$JDK_PKG" ]; then
        echo "下载后JDK压缩包仍不存在，请检查权限或磁盘空间"
        exit 1
    fi

    echo "JDK下载完成: $JDK_PKG"
else
    echo "JDK压缩包已存在: $JDK_PKG"
fi
echo ""



# 验证压缩包完整性
echo "验证JDK压缩包..."
if ! tar -tzf "$JDK_PKG" >/dev/null 2>&1; then
    echo "JDK压缩包损坏，删除并重新下载..."
    rm -f "$JDK_PKG"
    echo "请重新运行脚本"
	echo ""
    exit 1
fi
echo ""


# 清理旧的JDK目录
if [ -d "$JDK_DIR" ]; then
    echo "发现已存在的JDK安装，清理..."
    rm -rf "$JDK_DIR"
	echo ""
fi


# 解压JDK压缩包
echo "解压JDK压缩包..."
mkdir -p "$JDK_DIR"
tar -xzf "$JDK_PKG" -C "$JDK_DIR" --strip-components=1
echo ""


# 检查解压结果
if [ ! -f "$JDK_DIR/bin/java" ]; then
    echo "解压失败，JDK文件不完整"
	echo ""
    exit 1
fi


# 设置环境变量
echo "设置环境变量..."


# 备份原有的profile文件
cp /etc/profile /etc/profile.bak.$(date +%Y%m%d%H%M%S)


# 检查是否已设置JDK环境变量
if grep -q "JAVA_HOME=$JDK_DIR" /etc/profile; then
    echo "JDK环境变量已设置，跳过..."
else
    # 添加环境变量配置
    cat << EOF >> /etc/profile

# JDK Environment Variables
export JAVA_HOME=$JDK_DIR
export JRE_HOME=\$JAVA_HOME/jre
export PATH=\$JAVA_HOME/bin:\$JRE_HOME/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib:\$JRE_HOME/lib
EOF
    echo "环境变量已添加到 /etc/profile"
fi

echo ""



# 创建软链接（可选）
#ln -sfn "$JDK_DIR" "/usr/local/java" 2>/dev/null && echo "已创建软链接: /usr/local/java -> $JDK_DIR"


# 使环境变量生效
echo "使环境变量生效..."
source /etc/profile 2>/dev/null || {
    echo "注意: 需要重新登录或手动执行 'source /etc/profile' 使环境变量生效"
}
echo ""


# 验证JDK安装
echo "验证JDK安装..."
echo "JDK安装路径: $JDK_DIR"
if "$JDK_DIR/bin/java" -version; then
    echo "JDK安装验证成功！"
else
    echo "JDK安装验证失败！"
    exit 1
fi
echo ""


# 显示安装摘要
echo ""
echo "=== JDK安装完成 ==="
echo "安装路径: $JDK_DIR"
echo "压缩包路径: $JDK_PKG"
echo "环境变量文件: /etc/profile"
echo "使用方式:"
echo "  1. 重新登录终端"
echo "  2. 或执行: source /etc/profile"
echo "  3. 验证: java -version"
echo ""


