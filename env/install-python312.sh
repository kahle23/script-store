#!/bin/bash

# 启用严格模式：遇错停止、未定义变量报错、管道中任一命令失败则整个管道失败
set -euo pipefail;
# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/_func/_base.sh";
mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &

# 默认配置参数
DEFAULT_PYTHON_VERSION="3.12.6"
DEFAULT_INSTALL_BASE="/opt/python"
DEFAULT_ADD_TO_PATH="false"

# 显示使用说明
usage() {
    log_usage "用法: $0 [选项]"
    echo "选项:"
    echo "  -v, --version VERSION   指定Python版本 (默认: ${DEFAULT_PYTHON_VERSION})"
    echo "  -p, --path PATH         指定安装基础路径 (默认: ${DEFAULT_INSTALL_BASE})"
    echo "  -a, --add-to-path       是否添加到系统环境变量 (默认: 不添加)"
    echo "  -h, --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -v 3.11.5                  安装Python 3.11.5，不添加到环境变量"
    echo "  $0 -v 3.12.6 -a               安装Python 3.12.6并添加到环境变量"
    echo "  $0 --version 3.10.12 --add-to-path --path /opt/my_python  自定义安装"
}


# 参数解析
PYTHON_VERSION="${DEFAULT_PYTHON_VERSION}"
INSTALL_BASE="${DEFAULT_INSTALL_BASE}"
ADD_TO_PATH="${DEFAULT_ADD_TO_PATH}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        -p|--path)
            INSTALL_BASE="$2"
            shift 2
            ;;
        -a|--add-to-path) # 新增参数处理
            ADD_TO_PATH="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            usage
            exit 1
            ;;
    esac
done

# 验证版本号格式
if [[ ! "${PYTHON_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "错误: 无效的版本号格式 '${PYTHON_VERSION}'，应为 X.X.X 格式"
    exit 1
fi

# 计算目录名（将版本号中的点替换为空）
PYTHON_DIR_NAME="python${PYTHON_VERSION//./}"
PYTHON_INSTALL_DIR="${INSTALL_BASE}/${PYTHON_DIR_NAME}"
PKG_DOWNLOAD_BASE="/opt/pkg/python"


log_info "=== Python 环境安装配置 ==="
log_info "版本: Python ${PYTHON_VERSION}"
log_info "安装目录: ${PYTHON_INSTALL_DIR}"
log_info "添加到环境变量: ${ADD_TO_PATH}"
log_info "软件包缓存: ${PKG_DOWNLOAD_BASE}"
log_info "=========================="


# 1. 安装编译依赖 (CentOS 7 专用)
log_info "步骤 1/8: 安装编译依赖..."
yum groupinstall -y "Development Tools"
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel \
    readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel wget \
    libffi-devel epel-release openssl11 openssl11-devel

# 2. 创建目录
log_info "步骤 2/8: 创建安装目录..."
mkdir -p "${INSTALL_BASE}"
mkdir -p "${PKG_DOWNLOAD_BASE}"
chown -R $(whoami):$(whoami) "${INSTALL_BASE}"
chown -R $(whoami):$(whoami) "${PKG_DOWNLOAD_BASE}"

# 3. 下载Python源码（使用国内加速镜像）
cd "${PKG_DOWNLOAD_BASE}"
if [ ! -f "Python-${PYTHON_VERSION}.tgz" ]; then
    log_info "步骤 3/8: 下载 Python ${PYTHON_VERSION} 源码包..."
    
    # 尝试多个镜像源
    MIRRORS=(
        "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
        "https://mirrors.huaweicloud.com/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
        "https://npm.taobao.org/mirrors/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
    )
    
    for mirror in "${MIRRORS[@]}"; do
        log_info "尝试从镜像下载: ${mirror}"
        if wget --timeout=30 --tries=3 "${mirror}"; then
            log_info "下载成功!"
            break
        else
            log_error "镜像下载失败，尝试下一个..."
            rm -f "Python-${PYTHON_VERSION}.tgz"
        fi
    done
    
    # 如果所有镜像都失败，使用官方源
    if [ ! -f "Python-${PYTHON_VERSION}.tgz" ]; then
        log_error "镜像下载失败，尝试官方源..."
        wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
    fi
else
    log_info "步骤 3/8: 源码包已存在，跳过下载"
fi


# 4. 解压
log_info "步骤 4/8: 解压源码包..."
tar xf "Python-${PYTHON_VERSION}.tgz"
cd "Python-${PYTHON_VERSION}"


# 5. 配置编译参数（针对CentOS 7的OpenSSL优化）
log_info "步骤 5/8: 配置编译参数..."
export CFLAGS=$(pkg-config --cflags openssl11)
export LDFLAGS=$(pkg-config --libs openssl11)

./configure --prefix="${PYTHON_INSTALL_DIR}" \
            --enable-optimizations \
            --with-openssl=/usr/bin/openssl \
            --enable-shared

# 6. 编译安装
log_info "步骤 6/8: 编译安装Python (可能需要较长时间)..."
make -j $(nproc)
make altinstall

# 7. 根据参数选择是否配置环境变量
if [ "${ADD_TO_PATH}" = "true" ]; then
    log_info "步骤 7/8: 配置系统环境变量..."
    
    # 创建环境变量配置文件 [1](@ref)
    sudo tee "/etc/profile.d/${PYTHON_DIR_NAME}.sh" > /dev/null <<EOF
export PATH=${PYTHON_INSTALL_DIR}/bin:\$PATH
export LD_LIBRARY_PATH=${PYTHON_INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
EOF

    # 生效当前shell的环境变量
    export PATH="${PYTHON_INSTALL_DIR}/bin:$PATH"
    export LD_LIBRARY_PATH="${PYTHON_INSTALL_DIR}/lib:$LD_LIBRARY_PATH"
    
    log_info "已添加到系统环境变量"
else
    log_info "步骤 7/8: 跳过环境变量配置（根据用户参数设置）"
fi

# 8. 配置pip国内镜像源
log_info "步骤 8/8: 配置pip镜像源..."
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
EOF


# 验证安装
log_info "=== 安装完成验证 ==="
"${PYTHON_INSTALL_DIR}/bin/python${PYTHON_VERSION%.*}" --version
"${PYTHON_INSTALL_DIR}/bin/pip${PYTHON_VERSION%.*}" --version


log_info ""
log_info "=== 安装摘要 ==="
log_info "Python 版本: ${PYTHON_VERSION}"
log_info "安装目录: ${PYTHON_INSTALL_DIR}"
log_info "二进制路径: ${PYTHON_INSTALL_DIR}/bin"
log_info "已添加到环境变量: ${ADD_TO_PATH}"

if [ "${ADD_TO_PATH}" = "true" ]; then
    log_info "环境变量文件: /etc/profile.d/${PYTHON_DIR_NAME}.sh"
    log_info ""
    log_info "=== 使用说明 ==="
    log_info "1. 立即生效: source /etc/profile.d/${PYTHON_DIR_NAME}.sh"
    log_info "2. 直接调用: python${PYTHON_VERSION%.*} 或 pip${PYTHON_VERSION%.*}"
else
    log_info ""
    log_info "=== 使用说明 ==="
    log_info "1. 使用完整路径调用: ${PYTHON_INSTALL_DIR}/bin/python${PYTHON_VERSION%.*}"
    log_info "2. 手动临时添加环境变量: export PATH=${PYTHON_INSTALL_DIR}/bin:\$PATH"
fi

log_info ""
log_info "=== 多版本管理 ==="
log_info "要安装其他版本，重新运行此脚本并指定不同版本号即可"
log_info "示例: $0 -v 3.11.5 -a  # 安装Python 3.11.5并添加到环境变量"


