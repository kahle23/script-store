#!/bin/bash

# 遇到错误立即退出
set -e;
# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/_func/_base.sh";
mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &


# 定义变量
PYTHON_VERSION="3.12.6"  # 可以更改为其他版本，如 3.8.13, 3.10.8 等
INSTALL_DIR="/opt/python/python${PYTHON_VERSION%.*}"  # 例如 /opt/python/python3.9
SOURCE_DIR="/tmp/Python-${PYTHON_VERSION}"
# 主镜像站点
#DOWNLOAD_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
# 清华大学镜像
DOWNLOAD_URL="https://mirrors.tuna.tsinghua.edu.cn/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
# 阿里云镜像
#DOWNLOAD_URL="https://mirrors.aliyun.com/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
# 华为云镜像
#DOWNLOAD_URL="https://mirrors.huaweicloud.com/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
# 腾讯云镜像
#DOWNLOAD_URL="https://mirrors.cloud.tencent.com/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"


# 开始日志
mth_desc="安装 Python ${PYTHON_VERSION}"; log_method_start "$mth_desc";
log_info "安装目录: ${INSTALL_DIR}"


# 检查是否为root用户
if ! check_root; then
    exit 1
fi


# 1. 安装依赖包
log_info "步骤1: 安装编译依赖..."
yum groupinstall -y "Development Tools"
yum install -y \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    ncurses-devel \
    gdbm-devel \
    sqlite-devel \
    readline-devel \
    tk-devel \
    xz-devel \
    zlib-devel \
    wget \
    make
# 检查安装
if [[ $? -ne 0 ]]; then
    log_error "依赖安装失败，请检查网络连接和yum源配置"
    exit 1
fi


# 2. 下载Python源码
log_info "步骤2: 下载Python ${PYTHON_VERSION} 源码..."
cd /tmp
if [[ -f "Python-${PYTHON_VERSION}.tgz" ]]; then
    log_warn "源码包已存在，跳过下载"
else
    wget ${DOWNLOAD_URL}
    if [[ $? -ne 0 ]]; then
        log_error "下载失败，请检查网络连接或Python版本"
        exit 1
    fi
fi


# 3. 解压源码
log_info "步骤3: 解压源码..."
tar -xzf Python-${PYTHON_VERSION}.tgz
if [[ $? -ne 0 ]]; then
    log_error "解压失败"
    exit 1
fi


# 4. 编译和安装
log_info "步骤4: 编译安装Python ${PYTHON_VERSION}..."
cd ${SOURCE_DIR}

# 配置编译选项
# --prefix                自定义安装路径，避免覆盖系统默认Python
# --enable-optimizations  启用性能优化选项
./configure \
    --prefix=${INSTALL_DIR} \
    --enable-optimizations \
    --with-ssl \
    --enable-shared \
    LDFLAGS="-Wl,-rpath=${INSTALL_DIR}/lib"

if [[ $? -ne 0 ]]; then
    log_error "配置失败"
    exit 1
fi

# 编译（使用所有CPU核心加速编译）
make -j$(nproc)

if [[ $? -ne 0 ]]; then
    log_error "编译失败"
    exit 1
fi

# 安装，使用altinstall避免覆盖系统Python
make altinstall

if [[ $? -ne 0 ]]; then
    log_error "安装失败"
    exit 1
fi


# 5. 创建软链接
# 使用ln -sf命令强制创建软链接，覆盖旧版本（-s：创建符号链接（软链接），-f：强制覆盖现有文件）
# 检查软链接指向​
# ls -l /usr/bin/pip
# 验证版本号​
# pip --version
# 若软链接失效（ls -l显示红色或闪烁），检查目标路径是否存在：
# which pip3.12  # 确认pip3.12实际路径
log_info "步骤5: 创建软链接..."
ln -sf ${INSTALL_DIR}/bin/python${PYTHON_VERSION%.*} /usr/local/bin/python${PYTHON_VERSION%.*}
ln -sf ${INSTALL_DIR}/bin/pip${PYTHON_VERSION%.*} /usr/local/bin/pip${PYTHON_VERSION%.*}

# 创建pip3软链接
if [[ ! -f "/usr/local/bin/pip3" ]]; then
    ln -s /usr/local/bin/pip${PYTHON_VERSION%.*} /usr/local/bin/pip3
fi


# 6. 设置库路径
log_info "步骤6: 设置动态库路径..."
log_info "${INSTALL_DIR}/lib" > /etc/ld.so.conf.d/python${PYTHON_VERSION%.*}.conf
ldconfig


# 7. 验证安装
# 临时生效方式（当前终端会话）​​：export PATH="/usr/local/python3.12/bin:$PATH"
# 永久生效方式​​（用户环境，修改.bashrc或.bash_profile）：echo 'export PATH="/usr/local/python3.12/bin:$PATH"' >> ~/.bashrc ; source ~/.bashrc
# 永久生效方式​​（​系统级配置​​）：编辑/etc/profile并添加相同内容，适用于所有用户
# 配置国内镜像源​，提升pip下载速度：
# pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
log_info "步骤7: 验证安装..."
${INSTALL_DIR}/bin/python${PYTHON_VERSION%.*} --version
if [[ $? -eq 0 ]]; then
    log_info "========================================"
    log_info "Python ${PYTHON_VERSION} 安装成功!"
    log_info "安装目录: ${INSTALL_DIR}"
    log_info ""
    log_info "使用方式:"
    log_info "1. 直接使用: ${INSTALL_DIR}/bin/python${PYTHON_VERSION%.*}"
    log_info "2. 通过软链接: python${PYTHON_VERSION%.*} 或 /usr/local/bin/python${PYTHON_VERSION%.*}"
    log_info "3. pip: ${INSTALL_DIR}/bin/pip${PYTHON_VERSION%.*} 或 pip${PYTHON_VERSION%.*}"
    log_info ""
    log_info "如果需要设置为默认Python，可以运行:"
    log_info "  alternatives --install /usr/bin/python3 python3 ${INSTALL_DIR}/bin/python${PYTHON_VERSION%.*} 1"
    log_info "  alternatives --set python3 ${INSTALL_DIR}/bin/python${PYTHON_VERSION%.*}"
    log_info "========================================"
else
    log_error "安装验证失败"
    exit 1
fi


# 8. 清理临时文件（可选）
read -p "是否清理临时文件? (y/n, 默认y): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    log_info "清理临时文件..."
    rm -rf ${SOURCE_DIR}
    rm -f /tmp/Python-${PYTHON_VERSION}.tgz
fi


# 结束日志
log_method_end "$mth_desc";

