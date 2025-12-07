#!/bin/bash

# Nginx 安装脚本
# 安装路径：/usr/local/nginx

# 遇到错误立即退出
set -e

# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/_func/_base.sh";
mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &


# 检查 root 权限
if ! check_root; then
    exit 1
fi


# 安装依赖
log_info "安装依赖包..."
yum install -y epel-release
yum groupinstall -y "Development Tools"
yum install -y wget gcc pcre-devel zlib-devel openssl-devel

# 创建日志和运行目录
log_info "创建目录..."
mkdir -p /var/log/nginx
mkdir -p /var/run/nginx

# 下载并编译 Nginx
log_info "下载并编译 Nginx..."
cd /tmp
wget -c http://nginx.org/download/nginx-1.24.0.tar.gz
tar -zxvf nginx-1.24.0.tar.gz
cd nginx-1.24.0

# 配置 Nginx（使用 root 用户）
log_info "配置 Nginx..."
./configure \
    --prefix=/usr/local/nginx \
    --user=root \
    --group=root \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx/nginx.pid \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module

# 编译安装
make && make install

# 创建 systemd 服务
log_info "创建 systemd 服务..."
cat > /lib/systemd/system/nginx.service << 'EOF'
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target

[Service]
Type=forking
PIDFile=/var/run/nginx/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd
systemctl daemon-reload

# 测试 Nginx
log_info "测试 Nginx 配置..."
if /usr/local/nginx/sbin/nginx -t; then
    log_info "✓ Nginx 配置测试通过"
    
    # 启动 Nginx
    log_info "启动 Nginx 服务..."
    systemctl start nginx
    systemctl enable nginx
    
    if systemctl is-active --quiet nginx; then
        log_info "✓ Nginx 服务启动成功"
        log_info ""
        log_info "================================================"
        log_info "Nginx 已成功安装到 /usr/local/nginx"
        log_info "访问地址: http://$(hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")"
        log_info "日志文件: /var/log/nginx/"
        log_info "配置文件: /usr/local/nginx/conf/nginx.conf"
        log_info "================================================"
    else
        log_info "✗ Nginx 服务启动失败"
        systemctl status nginx
    fi
else
    log_info "✗ Nginx 配置测试失败"
    exit 1
fi

# 清理临时文件
rm -rf /tmp/nginx-1.24.0 /tmp/nginx-1.24.0.tar.gz

log_info "✓ Nginx 安装完成！"
