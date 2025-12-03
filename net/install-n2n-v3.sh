#!/bin/bash
# 官方Github：https://github.com/ntop/n2n/
# 二进制文件：https://github.com/lucktu/n2n
# Bug侠-N2N：https://bugxia.com/category/n2n_net
#
# 身份认证：https://github.com/ntop/n2n/blob/3.0-stable/doc/Authentication.md
# 【注意：要放开UDP协议，有些VPS的防火墙，区分TCP和UDP的，对应端口的TCP和UDP都要放开。】
# 【注意：community.list用户密码是有问题的，配置了之后，supernode怎么样都接收不到edge的请求了】


# 遇到错误立即退出
set -e

# 定义变量
N2N_DOWNLOAD_URL="https://github.com/lucktu/n2n/raw/refs/heads/master/Linux/n2n_v3_linux_x64_v3.1.1_r1255_static_by_heiye.tar.gz"
N2N_PKG_DIR="/opt/pkg/n2n"
N2N_PKG_NAME="n2n_v3_linux_x64_v3.1.1_r1255_static_by_heiye.tar.gz"
N2N_PKG="$N2N_PKG_DIR/$N2N_PKG_NAME"
# 工作目录
N2N_DIR="/opt/n2n"
N2N_BIN_DIR="$N2N_DIR/bin"
# 镜像站加速（https://gh-proxy.com）（https://ghfast.top）
N2N_DOWNLOAD_URL="https://gh-proxy.com/$N2N_DOWNLOAD_URL"


# 创建必要的目录
mkdir -p "$N2N_PKG_DIR"
mkdir -p "$N2N_DIR"


# 检查并下载N2N压缩包
if [ ! -f "$N2N_PKG" ]; then
    echo "N2N 压缩包不存在，开始下载..."

    # 检查是否支持下载工具
    if command -v wget &> /dev/null; then
        echo "使用 wget 下载 N2N..."
        if ! wget --no-check-certificate --no-cookies -O "$N2N_PKG" "$N2N_DOWNLOAD_URL"; then
            echo "下载失败，请检查网络连接或URL有效性"
            exit 1
        fi
    elif command -v curl &> /dev/null; then
        echo "使用 curl 下载 N2N..."
        if ! curl -L -o "$N2N_PKG" "$N2N_DOWNLOAD_URL"; then
            echo "下载失败，请检查网络连接或URL有效性"
            exit 1
        fi
    else
        echo "错误: 没有找到 wget 或 curl，无法下载 N2N"
        echo "请手动下载 N2N 并放置在: $N2N_PKG"
        echo "下载URL: $N2N_DOWNLOAD_URL"
        exit 1
    fi

    # 验证下载文件
    if [ ! -f "$N2N_PKG" ]; then
        echo "下载后 N2N 压缩包仍不存在，请检查权限或磁盘空间"
        exit 1
    fi

    echo "N2N 下载完成: $N2N_PKG"
else
    echo "N2N 压缩包已存在: $N2N_PKG"
fi
echo ""


# 验证压缩包完整性
echo "验证 N2N 压缩包..."
if ! tar -tzf "$N2N_PKG" >/dev/null 2>&1; then
    echo "N2N 压缩包损坏，删除并重新下载..."
    rm -f "$N2N_PKG"
    echo "请重新运行脚本"
	echo ""
    exit 1
fi
echo ""


# 清理旧的N2N目录
if [ -d "$N2N_BIN_DIR" ]; then
    echo "发现已存在的 N2N 安装，清理..."
    rm -rf "$N2N_BIN_DIR"
	echo ""
fi


# 解压N2N压缩包
echo "解压 N2N 压缩包..."
mkdir -p "$N2N_BIN_DIR"
tar -zxpf "$N2N_PKG" -C "$N2N_BIN_DIR"
# 清理掉 *_upx 相关文件
#ls "$N2N_BIN_DIR"/*_upx
rm -rf "$N2N_BIN_DIR"/*_upx
echo ""


# 检查解压结果
if [ ! -f "$N2N_BIN_DIR/supernode" ]; then
    echo "解压失败，N2N 文件不完整"
	echo ""
    exit 1
fi


# 授权
#chmod +x "$N2N_BIN_DIR/*"


# 创建 supernode.sh
echo "创建 supernode.sh ..."
cat > "$N2N_DIR/supernode.sh" << EOF
#!/bin/bash
# -p                 # 端口 | Supernode监听端口，默认 7654
# -a                 # IP段 | 用于自动分配IP，格式如 -a 10.1.1.0-10.1.3.0/24
# -c                 # 组名称配置文件路径 | 该配置文件中包含允许使用的组名称（别使用用户名、密码认证）
# -f                 # 前台运行（systemd 管理时需要加上 -f）
# -v                 # 输出更多日志
# -M                 # 连接断开重连不报错 | 关闭非用户名密码认证的群组的MAC和IP地址欺骗保护功能

# -V                 # 文本 | 自定义字符串（最长19位），用于在管理输出日志中展示
# -F                 # federation名称 | supernode 联盟名称，默认为 *Federation
# -l                 # 主机:端口 | 和 -F 配合，已知的一台Supernode地址和端口
# -t                 # 管理端口 | 用于管理supernode
# --management_password  # 文本 | 管理端的密码


# 主命令
$N2N_BIN_DIR/supernode -p 49527 -a 10.1.0.0-10.1.0.0/16 -M -f -v -c $N2N_DIR/community.list

EOF
# 授权
chmod +x "$N2N_DIR/supernode.sh"


# 创建 community.list
echo "创建 community.list ..."
cat > "$N2N_DIR/community.list" << EOF
# 允许连接到supernode的组名称列表
# 同时也支持正则形式的小组名称，例如name00~name19，可以这么表述
demo1
demo2

EOF


# 创建 edge.sh
echo "创建 edge.sh ..."
cat > "$N2N_DIR/edge.sh" << EOF
#!/bin/bash
# -l                 # 服务端（supernode）:端口 | N2N的服务端（中心节点）
# -c                 # 组名称 | 用于区分虚拟局域网
# -k                 # 密钥 | 用于虚拟局域网内传输的数据加密，留空则不加密
# -f                 # 前台运行（systemd 管理时需要加上 -f）
# -d                 # tun网卡名称 | 指定本机的N2N网卡，如果本机存在多个Tap网卡，可以使用此参数自定义，或留空使程序自动搜寻

# -a                 # 获取IP的模式 | 如需自定义虚拟IP，使用 -a IP地址 来自定义虚拟IP，如需自动获取（需服务端支持），留空即可
# -H                 # 数据包报头完整加密
# -P                 # 密钥 | 多个supernode组成联盟时，需要填入该参数以便认证

# 主命令
$N2N_BIN_DIR/edge -l n2n.demo.com:49527 -c demo1 -k "demokey" -f

EOF
# 授权
chmod +x "$N2N_DIR/edge.sh"


# 创建 systemd 的 supernode.service
echo "创建 systemd 的 supernode.service ..."
cat > "/etc/systemd/system/supernode.service" << EOF
[Unit]
Description=n2n supernode
After=network.target

[Service]
Type=simple
ExecStart=$N2N_DIR/supernode.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

EOF


# 创建 systemd 的 edge.service
echo "创建 systemd 的 edge.service ..."
cat > "/etc/systemd/system/edge.service" << EOF
[Unit]
Description=n2n edge
After=network.target

[Service]
Type=simple
ExecStart=$N2N_DIR/edge.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

EOF



# 创建 readme.txt
echo "创建 readme.txt ..."
cat > "$N2N_DIR/readme.txt" << EOF

# 参考命令

/etc/systemd/system/supernode.service
/etc/systemd/system/edge.service


systemctl daemon-reload

systemctl enable supernode
systemctl start supernode
systemctl stop supernode
systemctl status supernode

systemctl enable edge
systemctl start edge
systemctl stop edge
systemctl status edge


journalctl -u supernode -f
journalctl -u edge -f

EOF



