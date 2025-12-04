# def _print_log(msg): pass
# def _log_info(msg): pass
# def _log_warn(msg): pass
# def _log_error(msg): pass
# def _log_usage(msg): pass
# def importpy_local(file_path, use_isolated_namespace=True, show_log=False): pass
# def importpy_url(url, force_refresh=False, use_isolated_namespace=True, show_log=False): pass

# 加载远程 python 代码，会缓存 python 文件，每个 86400 秒重新下载一次
# 如果ide的话，会报错，可以在目标 python 文件此导入代码前声明方法，例如：def _log_info(param): pass
# 在Windows下的路径 C:\Users\<你的用户名>\AppData\Local\Temp\remote_<URL哈希值>_<天数>.py

# import urllib.request, tempfile, os, time, hashlib
# url = "https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/dev_tmp/_func/_base.py"
# cache = f"{tempfile.gettempdir()}/remote_script_{hashlib.md5(url.encode()).hexdigest()}_{int(time.time()//86400)}.py"
# not os.path.exists(cache) and urllib.request.urlretrieve(url, cache); exec(open(cache, encoding='utf-8').read())


LOG_COLORS = {
    'INFO ': '\033[92m',  # 绿色
    'WARN ': '\033[93m',  # 黄色
    'ERROR': '\033[91m',  # 红色
    'USAGE': '\033[94m',  # 蓝色
    'RESET': '\033[0m'    # 重置颜色
}


def _print_log(level, msg, show_log=True):
    """一个简单的、带级别和时间的基于 print 的日志输出"""
    if show_log:
        from datetime import datetime
        color = LOG_COLORS.get(level, LOG_COLORS['RESET'])
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"{color}[{level}]{LOG_COLORS['RESET']} {timestamp} - {msg}")


def _log_info(msg, show_log=True): _print_log('INFO ', msg, show_log)


def _log_warn(msg, show_log=True): _print_log('WARN ', msg, show_log)


def _log_error(msg, show_log=True): _print_log('ERROR', msg, show_log)


def _log_usage(msg, show_log=True): _print_log('USAGE', msg, show_log)


def _execute_python_script(script_content, source_identifier, use_isolated_namespace=True, show_log=False):
    """
    执行Python脚本内容
    参数:
        script_content (str): Python脚本内容
        source_identifier (str): 脚本来源标识，用于日志
        use_isolated_namespace (bool): 是否使用独立命名空间（默认True）
        show_log (bool): 是否显示日志
    返回:
        bool: 执行成功返回True，失败返回False
    """
    try:
        if use_isolated_namespace:
            # 使用独立命名空间执行脚本
            script_globals = {}
            exec(script_content, script_globals)
            # 可以选择性地将执行结果合并到全局命名空间，只合并非内置的变量和函数
            for key, value in script_globals.items():
                if not key.startswith('__'):
                    globals()[key] = value
            _log_info(f"Python脚本执行成功（独立命名空间）:  {source_identifier}", show_log)
        else:
            # 直接在全局命名空间执行脚本
            exec(script_content, globals())
            _log_info(f"Python脚本执行成功（全局命名空间）: {source_identifier}", show_log)
        return True
    except SyntaxError as e:
        _log_error(f"脚本语法错误({source_identifier}): {str(e)}", show_log)
        return False
    except Exception as e:
        _log_error(f"脚本执行错误({source_identifier}): {str(e)}", show_log)
        return False


def importpy_local(file_path, file_encoding='utf-8', use_isolated_namespace=True, show_log=False):
    """
    导入并执行本地Python脚本
    参数:
        file_path (str): 本地Python文件的路径
        file_encoding (str): 文件编码（默认utf-8）
        use_isolated_namespace (bool): 是否使用独立命名空间（默认True）
        show_log (bool): 是否显示日志（默认False）
    返回:
        bool: 执行成功返回True，失败返回False
    """
    import os, sys
    try:
        # 检查文件是否存在
        if not os.path.exists(file_path):
            _log_error(f"文件不存在: {file_path}", show_log)
            return False

        # 检查是否为Python文件
        if not file_path.endswith('.py'):
            _log_info(f"文件不是.py后缀，但仍尝试加载: {file_path}", show_log)

        # 读取文件内容
        with open(file_path, 'r', encoding=file_encoding) as f:
            script_content = f.read()
            _log_info(f"成功读取本地脚本: {file_path}", show_log)

        # 使用公共方法执行脚本
        return _execute_python_script(script_content
                                      , f"local_file:{file_path}", use_isolated_namespace, show_log)
    except Exception as e:
        _log_error(f"导入本地脚本失败: {str(e)}", show_log)
        return False


def importpy_url(url, url_timeout=30, file_encoding='utf-8', cache_dir=None, expire_hours=24,
                 force_refresh=False, use_isolated_namespace=True, show_log=False):
    """
    导入并执行远程Python脚本，支持缓存过期时间控制
    参数:
        url (str): 远程Python文件的URL地址，可以直接访问到的
        url_timeout (int): 下载超时时间（秒），默认30秒
        file_encoding (str): 文件编码（默认utf-8）
        cache_dir (str): 自定义缓存目录（默认使用系统临时目录）
        expire_hours (int/float): 缓存过期时间（小时），默认24小时
        force_refresh (bool): 是否强制重新下载文件，忽略缓存（默认False）
        use_isolated_namespace (bool): 是否使用独立命名空间（默认True）
        show_log (bool): 是否显示日志（默认False）
    返回:
        bool: 执行成功返回True，失败返回False
    """
    import urllib.request, tempfile, os, time, hashlib
    try:
        # 设置缓存目录
        if cache_dir is None: cache_dir = tempfile.gettempdir()
        elif not os.path.exists(cache_dir): os.makedirs(cache_dir, exist_ok=True)

        # 创建缓存文件名（基于URL的MD5）
        url_hash = hashlib.md5(url.encode()).hexdigest()

        # 计算过期时间戳
        if expire_hours == 0:
            time_stamp = "permanent"
        else:
            # 基于过期时间间隔计算时间戳
            expire_seconds = expire_hours * 3600
            time_stamp = str(int(time.time() // expire_seconds))

        # 要缓存的文件的全路径
        cache_file = os.path.normpath(f"{cache_dir}/remote_script_{url_hash}_{time_stamp}.py")

        # 检查缓存是否有效
        cache_valid = False
        if os.path.exists(cache_file):
            if expire_hours == 0:
                cache_valid = True
                _log_info(f"使用永久缓存: {cache_file}", show_log)
            else:
                file_mtime = os.path.getmtime(cache_file)
                current_time = time.time()
                cache_age_hours = (current_time - file_mtime) / 3600

                if cache_age_hours < expire_hours:
                    cache_valid = True
                    _log_info(f"使用缓存(已缓存{cache_age_hours:.1f}小时，有效期{expire_hours}小时): {cache_file}", show_log)
                else:
                    _log_info(f"缓存已过期({cache_age_hours:.1f}小时 > {expire_hours}小时)，重新下载", show_log)

        # 下载文件（如果缓存不存在、已过期或强制刷新）
        if force_refresh or not cache_valid or not os.path.exists(cache_file):
            _log_info(f"下载远程脚本: {url}", show_log)

            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
            req = urllib.request.Request(url, headers=headers)
            response = urllib.request.urlopen(req, timeout=url_timeout)
            script_content = response.read().decode(file_encoding)

            # 保存到缓存文件
            with open(cache_file, 'w', encoding=file_encoding) as f:
                f.write(script_content)
            _log_info(f"脚本已缓存至: {cache_file}", show_log)
        else:
            # 读取缓存文件
            with open(cache_file, 'r', encoding=file_encoding) as f:
                script_content = f.read()

        # 使用公共方法执行脚本
        return _execute_python_script(script_content
                                      , f"remote_url:{url}", use_isolated_namespace, show_log)
    except urllib.error.URLError as e:
        if isinstance(e.reason, TimeoutError) or "timed out" in str(e.reason):
            _log_error(f"下载超时({url_timeout}秒): {str(e)}", show_log)
        else:
            _log_error(f"网络错误: {str(e)}", show_log)
        return False
    except Exception as e:
        _log_error(f"导入远程脚本失败: {str(e)}", show_log)
        return False





