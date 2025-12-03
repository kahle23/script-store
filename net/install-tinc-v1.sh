#!/bin/bash
# ==================================================
# Tinc VPN 自动安装配置脚本
# [功能]：自动安装并配置 Tinc VPN
# [用法]：./install-tinc.sh <网络名> <主机名> <网络地址>
# ==================================================


# 遇到错误立即退出
set -e

# 参数检查
if [ $# -ne 3 ]; then
    echo "错误: 请提供Tinc网络名、主机名和网络地址作为参数"
    echo "用法: $0 <网络名> <主机名> <网络地址>"
    echo "示例: $0 myvpn node1 10.0.0.1/24"
    exit 1
fi


# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用root权限运行此脚本"
    exit 1
fi


# 常量声明
NET_NAME=$1
HOST_NAME=$2
NETWORK_ADDR=$3
TINC_DIR="/etc/tinc/$NET_NAME"
TINC_HOSTS_DIR="$TINC_DIR/hosts"


# 开始日志
echo "=== 开始安装配置Tinc VPN ==="
echo "网络名: $NET_NAME"
echo "主机名: $HOST_NAME"
echo "IP地址: $NETWORK_ADDR"
echo ""


# 安装 Tinc （指定版本，防止后面安装时差异过大）
echo "步骤1: 安装Tinc软件包..."
if command -v yum &> /dev/null; then
    yum install -y tinc-1.0.36
elif command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y tinc-1.0.36
else
    echo "错误: 不支持的包管理器(yum或apt-get)"
    exit 1
fi
echo ""


# 创建目录结构
echo "步骤2: 创建目录结构..."
mkdir -p /etc/tinc
cd /etc/tinc
mkdir -p "$TINC_HOSTS_DIR"
pwd
ls -lh
echo ""


# 创建基础配置文件
echo "步骤3: 创建基础配置文件..."

# 创建 tinc.conf
cat > "$TINC_DIR/tinc.conf" << EOF
# Tinc VPN 配置
Name = $HOST_NAME
Interface = $NET_NAME
Mode = switch
Compression = 9
Cipher = aes-256-cbc
Digest = sha256
PrivateKeyFile = /etc/tinc/$NET_NAME/rsa_key.priv
ConnectTo = demo1
#ConnectTo = demo2
EOF

# 创建 tinc-up 脚本
#ip route add $NETWORK_ADDR dev \$INTERFACE
cat > "$TINC_DIR/tinc-up" << EOF
#!/bin/sh
ip link set \$INTERFACE up
ip addr add $NETWORK_ADDR dev \$INTERFACE
EOF

# 创建 tinc-down 脚本
#ip route del $NETWORK_ADDR dev \$INTERFACE
cat > "$TINC_DIR/tinc-down" << EOF
#!/bin/sh
ip addr del $NETWORK_ADDR dev \$INTERFACE
ip link set \$INTERFACE down
EOF

# 创建 ping-test.sh 测试脚本
cat > "$TINC_DIR/ping-test.sh" << EOF
#!/bin/sh
ping 10.0.0.1
EOF

# 设置执行权限
chmod +x "$TINC_DIR"/tinc-*
chmod +x "$TINC_DIR"/ping-test.sh

# 创建其他主机配置文件
cat > "$TINC_HOSTS_DIR/demo1" << EOF
Address = 1.1.1.1
Port = 10000

-----BEGIN RSA PUBLIC KEY-----
testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
testtesttesttesttesttesttesttesttesttesttesttesttesttesttestte==
-----END RSA PUBLIC KEY-----

EOF

# 打印目录
ls -lh "$TINC_DIR"
echo ""


# 生成密钥对（通过输入两个换行来自动选择默认密钥文件路径）
echo "步骤4: 生成RSA密钥对(直接使用默认路径)..."
tincd -n "$NET_NAME" -K 4096 <<< $'\n\n'
ls -lh "$TINC_DIR"
echo ""


# 创建自述文件
echo "步骤5: 生成自述文件"
cat > "$TINC_DIR/readme.txt" << EOF
网络名: $NET_NAME
主机名: $HOST_NAME
IP地址: $NETWORK_ADDR
配置目录: $TINC_DIR
主机配置文件: $TINC_HOSTS_DIR/$HOST_NAME

后续步骤:
1. 在本机的 $TINC_HOSTS_DIR/ 目录中添加其他节点的配置文件。
2. 在本机的 $TINC_DIR/tinc.conf 中添加 ConnectTo 指令连接其他节点。
3. 将本机的 $TINC_HOSTS_DIR/$HOST_NAME 文件分发给其他节点。
4. 根据需要调整 $TINC_DIR 中的 tinc-up 和 tinc-down 的IP地址设置。
5. 启动服务: tincd -n $NET_NAME
6. 设置开机自启: 
        设置主要服务：systemctl enable tinc
        查询服务状态：systemctl status tinc
        设置网络服务：systemctl enable tinc@$NET_NAME
        查询服务状态：systemctl status tinc@$NET_NAME
EOF

# 打印自述文件
cat "$TINC_DIR/readme.txt"
echo ""


# 结束日志
echo "=== 结束安装配置Tinc VPN ==="

