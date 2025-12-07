#!/bin/bash
# ==================================================
# 系统初始化配置脚本
# [功能]：设置主机名、时区、安装软件、创建目录、配置防火墙
# [日期]：2025-12-04
# [作者]：Kahle
# ==================================================

# 遇到错误立即退出
set -e;
# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/_func/_base.sh";
mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &


# 关联数组，定义不同的软件包组
declare -A PACKAGE_GROUPS
# 基础工具包 (所有服务器都安装)
PACKAGE_GROUPS["base"]="epel-release lrzsz htop zip unzip tar net-tools bind-utils wget curl"
# 开发编译工具包
PACKAGE_GROUPS["dev"]="gcc-c++ openssl-devel c-ares-devel libuuid-devel make"
# 网络相关工具包
#PACKAGE_GROUPS["net"]="telnet tcpdump traceroute nmap"
# 数据库相关工具包
#PACKAGE_GROUPS["db"]="mariadb redis"
# 默认安装的包组
DEFAULT_GROUPS="base"



# 设置主机名
set_hostname() {
    local hostname="$1"
    if [[ -z "$hostname" ]]; then
        log_warn "未提供主机名参数，跳过设置。"
        return 0
    fi
    log_info "正在设置主机名为: $hostname"
    if hostnamectl set-hostname "$hostname"; then
        log_info "主机名设置成功。"
    else
        log_error "主机名设置失败！"
        return 1
    fi
}


# 设置时区
set_timezone() {
    local timezone="Asia/Shanghai"
    log_info "正在设置时区为: $timezone"
    if timedatectl set-timezone "$timezone"; then
        log_info "时区设置成功。"
    else
        log_error "时区设置失败！"
        return 1
    fi
}


# 安装软件包
install_packages() {
    local mth_desc="安装软件包"; log_method_start "$mth_desc";
    # 例如："dev,net"
    local requested_groups_param="$1" 
    local groups_to_install=()
    local all_packages=""

    # 1. 始终安装默认包组
    log_info "默认包组: $DEFAULT_GROUPS"
    all_packages="${PACKAGE_GROUPS[$DEFAULT_GROUPS]}"

    # 2. 如果用户提供了参数，则解析并添加对应的包组
    if [[ -n "$requested_groups_param" ]]; then
        # 将逗号分隔的参数转换为数组
        IFS=',' read -r -a requested_groups <<< "$requested_groups_param"

        for group in "${requested_groups[@]}"; do
            # 去除首尾空格
            group=$(echo "$group" | xargs)
            if [[ -z "$group" ]]; then
                continue
            fi
            # 检查请求的包组是否在预定义列表中
            if [[ -n "${PACKAGE_GROUPS[$group]:-}" ]]; then
                log_info "添加包组: $group"
                groups_to_install+=("$group")
                all_packages+=" ${PACKAGE_GROUPS[$group]}"
            else
                log_warn "未知的软件包组: '$group'，将跳过。可用的包组有: ${!PACKAGE_GROUPS[*]}"
            fi
        done
    fi

    # 3. 安装所有必要的软件包
    if [[ -n "$all_packages" ]]; then
        log_info "开始安装软件包..."
        log_info "将安装的包组: $DEFAULT_GROUPS ${groups_to_install[*]}"
        log_info "完整的软件包列表: $all_packages"
        
        if yum -y install $all_packages; then
            log_info "软件包安装成功。"
        else
            log_error "软件包安装失败！"
            return 1
        fi
    else
        log_info "没有需要安装的软件包。"
    fi

    # 结束
    log_method_end "$mth_desc"
}


# 创建常用目录
create_directories() {
    local base_dir="/home/data"
    # 使用数组定义要创建的目录，代码更简洁
    local dirs=(
        "$base_dir"
        "$base_dir/tool"
        "$base_dir/pkg"
        "$base_dir/app"
        "$base_dir/web"
		"/opt/pkg"
    )

    log_info "开始创建目录结构..."
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir"; then
                log_info "目录创建成功: $dir"
            else
                log_error "目录创建失败: $dir"
                return 1
            fi
        else
            log_info "目录已存在，跳过: $dir"
        fi
    done
}


# 防火墙管理，通过参数控制
manage_firewall() {
    # 接收参数：disable 或 enable
    local action="$1"

    case "$action" in
        disable)
            log_warn "正在停止并禁用防火墙 (firewalld)..."
            if systemctl stop firewalld && systemctl disable firewalld; then
                log_info "防火墙已关闭并禁用。"
            else
                log_error "防火墙操作失败！"
                return 1
            fi
            ;;
        enable)
            log_info "配置防火墙：保持开启状态，确保SSH端口放行。"
            if ! systemctl is-active --quiet firewalld; then
                log_info "启动防火墙..."
                systemctl start firewalld
            fi
            systemctl enable firewalld
            # 确保SSH端口（22）开放，防止锁死远程连接 [1](@ref)
            if firewall-cmd --permanent --add-service=ssh; then
                log_info "防火墙SSH服务规则已添加。"
            else
                log_warn "添加SSH防火墙规则时遇到问题，请手动检查。"
            fi
            firewall-cmd --reload
            log_info "防火墙已启用，SSH端口已放行。"
            ;;
        *)
            log_warn "未提供有效的防火墙操作参数。当前防火墙状态："
            systemctl status firewalld --no-pager -l || true
            log_usage "合法参数: 'disable' 或 'enable'"
            return 0
            ;;
    esac
}


# 显示用法信息
usage() {
    log_info1 "用法: $SCRIPT_FILE_NAME [选项]"
    echo ""
    echo "选项:"
    echo "  --hostname NAME      设置系统主机名为 NAME"
    echo "  --firewall ACTION    对防火墙执行 ACTION (enable 或 disable)"
    echo "  --packages LIST      指定要安装的附加软件包组，用逗号分隔"
    echo "                       可用包组: ${!PACKAGE_GROUPS[*]}"
    echo "  -h, --help           显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $SCRIPT_FILE_NAME --hostname my-server --firewall disable"
    echo "    # 设置主机名，关闭防火墙，仅安装基础包(base)，同步时间"
    echo "  $SCRIPT_FILE_NAME --packages dev"
    echo "    # 不设置主机名，默认防火墙配置，安装基础包和开发工具"
    echo "  $SCRIPT_FILE_NAME --packages dev,net"
    echo "    # 安装基础包、开发工具和网络诊断工具"
    echo "  $SCRIPT_FILE_NAME --packages dev --firewall enable"
    echo "    # 组合使用多个参数"
}


# 主函数，解析参数并执行
main() {
    local hostname=""
    local packages_arg=""
    local firewall_action=""

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --hostname)
                hostname="$2"
                shift 2
                ;;
            --firewall)
                firewall_action="$2"
                shift 2
                ;;
            --packages)
                packages_arg="$2"
                shift 2
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

    log_info "开始执行系统初始化脚本..."

    # 执行各项任务
    set_hostname "$hostname"
    set_timezone
    install_packages "$packages_arg"
    create_directories

    # 防火墙配置
    if [[ -n "$firewall_action" ]]; then
        manage_firewall "$firewall_action"
    else
        log_warn "未提供 --firewall 参数，跳过防火墙配置。"
    fi

    log_info "系统初始化配置完成！"
}


# 脚本主入口
main "$@"



