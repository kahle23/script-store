#!/bin/bash
# ==================================================
# 基础功能脚本
# [功能]：基础功能脚本，提供了日志、远程引入等方法
# [日期]：2025-12-04
# [作者]：Kahle
# ==================================================

# >> 引入方式 <<
# [进程替换]：无磁盘I/O，使用管道内存传输，更快（需要给文件授权，通过 ./test.sh 执行）
#REMOTE_SCRIPT="https://示例URL/test.sh"; source <(curl -Ls "$REMOTE_SCRIPT")
# [临时文件]：有磁盘写入和读取操作，适合处理大文件
#{ REMOTE_SCRIPT="https://示例URL/test.sh"; temp_file=$(mktemp) && curl -Ls "$REMOTE_SCRIPT" > "$temp_file" && source "$temp_file"; rm -f "$temp_file"; }

# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
#_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/_func/_base.sh";
#mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &


# 脚本文件名称
readonly SCRIPT_FILE_NAME="$(basename "$0")";
# 日志颜色
readonly LOG_COLOR_NO='\033[0m';
readonly LOG_COLOR_RED='\033[0;31m';
readonly LOG_COLOR_GREEN='\033[0;32m';
readonly LOG_COLOR_BLUE='\033[0;34m';
readonly LOG_COLOR_YELLOW='\033[1;33m';


# 通用日志方法
# 参数1: 日志级别
# 参数2: 颜色代码（默认: LOG_COLOR_NO）
# 参数3: 是否输出到stderr（1=是, 0=否, 默认：0）
# 参数4+: 日志消息
_log() {
    local level="$1"
    local color="${2:-$LOG_COLOR_NO}"
    local to_stderr="${3:-0}"
    local message="${@:4}"

    # 构建时间戳，构造日志消息
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_message="${timestamp} ${color}[${level}]${LOG_COLOR_NO} ${message}"

    # 根据to_stderr决定输出位置
    if [[ ${to_stderr} -eq 1 ]]; then
        echo -e "${log_message}" >&2
    else
        echo -e "${log_message}"
    fi
}

# 常用日志方法
log_info()  { _log "INFO " "${LOG_COLOR_GREEN}"   0 "$@"; }
log_info1() { _log "INFO " "${LOG_COLOR_BLUE}"    0 "$@"; }
log_warn()  { _log "WARN " "${LOG_COLOR_YELLOW}"  0 "$@"; }
log_error() { _log "ERROR" "${LOG_COLOR_RED}"     1 "$@"; }


# 方法开始、结束日志方法
# 示例：
#local mth_desc="方法描述"; log_method_start "$mth_desc";
#log_method_end "$mth_desc";
log_method_start() {
    log_info1 ">>>>>>>>>>>>>>>> [start] >>>>>>>>>>>>>>>>";
    log_info1 ">>>>[  $1  ]<<<<";
}
log_method_end() {
    log_info1 "<<<<<<<<<<<<<<<< [ end ] <<<<<<<<<<<<<<<<\n";
}


# 检查root权限
# 示例：
#if ! check_root; then
#    exit 1
#fi
check_root() {
    # 使用 id -u 最安全
    if [ "$(id -u 2>/dev/null)" != "0" ]; then
        # 如果 id 命令不可用，尝试其他方法
        if [ -n "$EUID" ] && [ "$EUID" -eq 0 ]; then
            return 0
        fi
        # 如果 $EUID 不存在，尝试 whoami
        if [ "$(whoami 2>/dev/null)" = "root" ]; then
            return 0
        fi
        # 错误提示
        log_error "错误: 需要root权限" >&2
        log_error "请使用: sudo $0 $*" >&2
        return 1
    fi
    return 0
}


# 下载并执行远程脚本的通用函数
# 参数1: 远程脚本URL
# 参数2: 本地缓存目录（可选，默认/tmp/remote-func2512）
# 参数3: 缓存天数（可选，默认1天）
# 示例[基本用法]：load_remote_script "远程脚本的URL"
# 示例[指定缓存目录和缓存天数]：load_remote_script "远程脚本的URL" "/tmp/myscripts" 3
load_remote_script() {
    local remote_script_url="$1"
    local cache_dir="${2:-/tmp/remote-func2512}"
    local cache_days="${3:-1}"
    # 验证参数
    if [[ -z "$remote_script_url" ]]; then
        log_error "错误: 必须提供远程脚本URL"
        return 1
    fi
    # 提取脚本文件名
    local script_name=$(basename "$remote_script_url")
    local cache_file="$cache_dir/${script_name}_$(date +%Y%m%d)"
    # 创建缓存目录
    mkdir -p "$cache_dir" || {
        log_error "错误: 无法创建缓存目录 $cache_dir"
        return 1
    }
    # 下载脚本（如果缓存不存在）
    if [[ ! -f "$cache_file" ]]; then
        # 下载内容
        if command -v curl &> /dev/null; then
            log_info "使用curl下载: $remote_script_url"
            if ! curl -Ls "$remote_script_url" > "$cache_file"; then
                log_error "错误: 下载失败"
                rm -f "$cache_file"
                return 1
            fi
        elif command -v wget &> /dev/null; then
            log_info "使用wget下载: $remote_script_url"
            if ! wget -qO- "$remote_script_url" > "$cache_file"; then
                log_error "错误: 下载失败"
                rm -f "$cache_file"
                return 1
            fi
        else
            log_error "错误: 未找到curl或wget"
            return 1
        fi
        # 验证下载内容
        if [[ ! -s "$cache_file" ]]; then
            log_error "错误: 下载内容为空"
            rm -f "$cache_file"
            return 1
        fi
    else
        log_info "使用缓存: $cache_file"
    fi
    # 执行脚本
    source "$cache_file" || {
        log_error "错误: 脚本执行失败"
        return 1
    }
    # 清理旧缓存（后台执行）
    if [[ -d "$cache_dir" ]]; then
        (find "$cache_dir" -name "${script_name}_*" -mtime "+${cache_days}" -delete 2>/dev/null) &
    fi
    # 结束
    return 0
}




