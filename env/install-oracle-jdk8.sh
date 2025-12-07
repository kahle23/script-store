#!/bin/bash
# ==================================================
# JDK 自动安装脚本
# [功能]：检查并自动下载安装 JDK（修改路径直接改脚本把）
# [用法]：./install-oracle-jdk8.sh
# ==================================================

# 遇到错误立即退出
set -e;
# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/_func/_base.sh";
mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &


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
    log_info "JDK压缩包不存在，开始下载..."

    # 检查是否支持下载工具
    if command -v wget &> /dev/null; then
        log_info "使用 wget 下载JDK..."
        if ! wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -O "$JDK_PKG" "$JDK_DOWNLOAD_URL"; then
            log_error "下载失败，请检查网络连接或URL有效性"
            exit 1
        fi
    elif command -v curl &> /dev/null; then
        log_info "使用 curl 下载JDK..."
        if ! curl -L -b "oraclelicense=accept-securebackup-cookie" -o "$JDK_PKG" "$JDK_DOWNLOAD_URL"; then
            log_error "下载失败，请检查网络连接或URL有效性"
            exit 1
        fi
    else
        log_error "错误: 没有找到 wget 或 curl，无法下载JDK"
        log_error "请手动下载JDK并放置在: $JDK_PKG"
        log_error "下载URL: $JDK_DOWNLOAD_URL"
        exit 1
    fi

    # 验证下载文件
    if [ ! -f "$JDK_PKG" ]; then
        log_error "下载后JDK压缩包仍不存在，请检查权限或磁盘空间"
        exit 1
    fi

    log_info "JDK下载完成: $JDK_PKG"
else
    log_warn "JDK压缩包已存在: $JDK_PKG"
fi



# 验证压缩包完整性
log_info "验证JDK压缩包..."
if ! tar -tzf "$JDK_PKG" >/dev/null 2>&1; then
    log_error "JDK压缩包损坏，删除并重新下载..."
    rm -f "$JDK_PKG"
    log_error "请重新运行脚本"
    exit 1
fi


# 清理旧的JDK目录
if [ -d "$JDK_DIR" ]; then
    log_warn "发现已存在的JDK安装，清理..."
    rm -rf "$JDK_DIR"
fi


# 解压JDK压缩包
log_info "解压JDK压缩包..."
mkdir -p "$JDK_DIR"
tar -xzf "$JDK_PKG" -C "$JDK_DIR" --strip-components=1


# 检查解压结果
if [ ! -f "$JDK_DIR/bin/java" ]; then
    log_warn "解压失败，JDK文件不完整"
    exit 1
fi


# 设置环境变量
log_info "设置环境变量..."


# 备份原有的profile文件
cp /etc/profile /etc/profile.bak.$(date +%Y%m%d%H%M%S)


# 检查是否已设置JDK环境变量
if grep -q "JAVA_HOME=$JDK_DIR" /etc/profile; then
    log_info "JDK环境变量已设置，跳过..."
else
    # 添加环境变量配置
    cat << EOF >> /etc/profile

# JDK Environment Variables
export JAVA_HOME=$JDK_DIR
export JRE_HOME=\$JAVA_HOME/jre
export PATH=\$JAVA_HOME/bin:\$JRE_HOME/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib:\$JRE_HOME/lib
EOF
    log_info "环境变量已添加到 /etc/profile"
fi



# 创建软链接（可选）
#ln -sfn "$JDK_DIR" "/usr/local/java" 2>/dev/null && echo "已创建软链接: /usr/local/java -> $JDK_DIR"


# 使环境变量生效
log_info "使环境变量生效..."
source /etc/profile 2>/dev/null || {
    log_warn "注意: 需要重新登录或手动执行 'source /etc/profile' 使环境变量生效"
}


# 验证JDK安装
log_info "验证JDK安装..."
log_info "JDK安装路径: $JDK_DIR"
if "$JDK_DIR/bin/java" -version; then
    log_info "JDK安装验证成功！"
else
    log_error "JDK安装验证失败！"
    exit 1
fi


# 显示安装摘要
log_info "=== JDK安装完成 ==="
log_info "安装路径: $JDK_DIR"
log_info "压缩包路径: $JDK_PKG"
log_info "环境变量文件: /etc/profile"
log_info "使用方式:"
log_info "  1. 重新登录终端"
log_info "  2. 或执行: source /etc/profile"
log_info "  3. 验证: java -version"


