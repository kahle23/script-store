

# Chronyd时间同步脚本
# date -s "2025-08-25 17:51:00"
# date '+%Y-%m-%d %H:%M:%S %Z'
configure_and_sync_ntp() {
    local mth_desc="chronyd时间同步"; log_method_start "$mth_desc";
    
    # 检查root权限
    if ! check_root; then 
        exit 1 
    fi
	
	
    # 1. 检查chronyd是否安装
    log_info ">> 1. 检查chronyd是否安装..."
    if ! command -v chronyd &>/dev/null; then
        log_info "正在安装chrony..."
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y chrony
        elif command -v yum &>/dev/null; then
            yum install -y chrony
        else
            log_error "错误: 不支持的包管理器"
            return 1
        fi
    fi
    
    # 2. 检查systemd服务状态
    log_info ">> 2. 检查chronyd服务状态..."
    if systemctl is-active chronyd &>/dev/null; then
        log_info "✓ chronyd服务已在运行"
        SERVICE_WAS_RUNNING=true
    else
        log_info "✗ chronyd服务未运行，尝试启动..."
        SERVICE_WAS_RUNNING=false
        
        # 检查并修复权限问题
        mkdir -p /run/chrony
        chown chrony:chrony /run/chrony
        chmod 750 /run/chrony
        # 清理可能存在的旧pid文件
        rm -f /run/chrony/chronyd.pid 2>/dev/null
        
        # 启动服务
        if systemctl start chronyd; then
            log_info "✓ chronyd服务启动成功"
        else
            log_error "错误: chronyd服务启动失败"
            systemctl status chronyd --no-pager -l
            return 1
        fi
    fi
	# 确保服务启用
    if ! systemctl is-enabled chronyd &>/dev/null; then
        log_info "启用chronyd开机自启..."
        systemctl enable chronyd
    fi
	
	
    # 2. 显示当前配置
    log_info ">> 3. 当前chrony配置:"
    # 查找配置文件
    if [ -f /etc/chrony/chrony.conf ]; then
        CONFIG_FILE="/etc/chrony/chrony.conf"
    elif [ -f /etc/chrony.conf ]; then
        CONFIG_FILE="/etc/chrony.conf"
    else
        log_error "未找到chrony配置文件"
        CONFIG_FILE=""
    fi
    # 显示配置文件
    if [ -n "$CONFIG_FILE" ]; then
        log_info "配置文件: $CONFIG_FILE"
        grep "^pool\|^server" "$CONFIG_FILE" 2>/dev/null | head -5
    fi

    
    # 4. 等待同步
    log_info ">> 4. 等待时间同步..."
    for i in {1..10}; do
        if chronyc tracking 2>/dev/null | grep -q "Leap status.*Normal"; then
            log_info "✓ 时间同步成功 (等待${i}秒)"
            break
        fi
        log_info "..."
        sleep 2
        
        if [ $i -eq 10 ]; then
            log_warn "⚠ 同步较慢，但服务正在运行..."
        fi
    done
    
    # 5. 显示结果
    log_info ">> 7. 同步状态:"
    log_info "系统时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    log_info ""
    
    # 显示chrony状态
    if command -v chronyc &>/dev/null; then
        log_info "chrony跟踪状态:"
        chronyc tracking | grep -E "(Leap status|System time|Last offset|Root delay|Reference ID)"
    fi
    
	log_method_end "$mth_desc"
    return 0
}



# 将系统时间同步到硬件时钟
# hwclock --set --date="2025-08-25 17:51:00"
# hwclock --show
sync_to_hardware_clock() {
    local mth_desc="将系统时间同步到硬件时钟"; log_method_start "$mth_desc";

    # 1. 工具检查
    if ! command -v hwclock &>/dev/null; then
        log_error "未找到 hwclock 工具"
        return 1
    fi
    
    # 2. 显示当前时间
    log_info "同步前的时间:"
    log_info "系统时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    
    local hw_time
    if hw_time=$(hwclock --show 2>/dev/null); then
        log_info "硬件时间: $hw_time"
    else
        log_error "硬件时间: 无法读取"
    fi
    
    # 3. 检测硬件时钟模式
    local hwclock_mode="local"  # 默认假设为本地时间
    if [[ -f /etc/adjtime ]] && grep -q "^UTC" /etc/adjtime 2>/dev/null; then
        hwclock_mode="utc"
        log_info "检测到硬件时钟使用 UTC 时间"
    else
        log_info "检测到硬件时钟使用本地时间"
    fi
    
    # 4. 同步到硬件时钟
    log_info "正在同步到硬件时钟..."
    
    local sync_options=()
    [[ "$hwclock_mode" == "utc" ]] && sync_options+=(--utc)
    
    # 首次同步尝试
    if hwclock --systohc "${sync_options[@]}" 2>/dev/null; then
        log_info "硬件时钟已更新 (${hwclock_mode^^}模式)"
    else
        # 后备同步方案
        log_warn "首选同步方法失败，尝试备用方法..."
        
        local sync_methods=(
            "hwclock --systohc"                    # 本地时间
            "hwclock --systohc --utc"              # UTC时间
            "hwclock --systohc --directisa"        # 直接ISA访问
        )
        
        local sync_success=false
        for method in "${sync_methods[@]}"; do
            if eval "$method" 2>/dev/null; then
                log_info "硬件时钟已更新 (通过: ${method})"
                sync_success=true
                break
            fi
        done
        
        if ! $sync_success; then
            log_error "所有硬件时钟同步方法都失败"
            return 1
        fi
    fi
    
    # 5. 验证同步结果
    log_info "同步后的时间:"
    log_info "系统时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    
    if hw_time=$(hwclock --show 2>/dev/null); then
        log_info "硬件时间: $hw_time"
        
        # 计算时间差
        local sys_seconds hw_seconds time_diff
        sys_seconds=$(date +%s)
        
        # 将硬件时间转换为秒数
        if [[ "$hwclock_mode" == "utc" ]]; then
            hw_seconds=$(date -d "$hw_time" +%s 2>/dev/null)
        else
            # 对于本地时间，需要考虑时区
            hw_seconds=$(date -d "$hw_time" +%s 2>/dev/null)
        fi
        
        if [[ -n "$hw_seconds" ]] && [[ "$hw_seconds" -gt 0 ]]; then
            time_diff=$((sys_seconds - hw_seconds))
            local abs_diff=${time_diff#-}  # 绝对值
            
            if [[ $abs_diff -le 2 ]]; then
                log_info "系统时间与硬件时钟同步成功 (时间差: ${abs_diff}秒)"
            elif [[ $abs_diff -le 5 ]]; then
                log_warn "系统时间与硬件时钟有较小差异 (时间差: ${abs_diff}秒)"
            else
                log_warn "系统时间与硬件时钟存在较大差异 (时间差: ${abs_diff}秒)"
            fi
        else
            log_warn "无法计算精确的时间差"
        fi
    else
        log_error "硬件时间: 无法读取"
    fi
    
    log_method_end "$mth_desc";
    return 0
}




