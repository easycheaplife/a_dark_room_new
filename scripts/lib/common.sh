#!/bin/bash

# A Dark Room Scripts 共享函数库
# 提供通用的日志、环境检查、错误处理等功能

# 防止重复加载
if [[ "${ADARKROOM_COMMON_LOADED:-}" == "true" ]]; then
    return 0
fi
export ADARKROOM_COMMON_LOADED=true

# 颜色定义
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# 日志函数
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

log_debug() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        printf "${YELLOW}[DEBUG]${NC} %s\n" "$1"
    fi
}

# 环境检查函数
check_flutter_environment() {
    log_info "检查Flutter环境..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter未安装或不在PATH中"
        return 1
    fi
    
    local flutter_version=$(flutter --version | head -n 1)
    log_info "Flutter版本: $flutter_version"
    
    # 检查Flutter Web支持
    if ! flutter config | grep -q "enable-web: true"; then
        log_warning "Flutter Web支持未启用，正在启用..."
        flutter config --enable-web
    fi
    
    log_success "Flutter环境检查完成"
    return 0
}

# 检查项目环境
check_project_environment() {
    log_info "检查项目环境..."
    
    # 检查是否在项目根目录
    if [ ! -f "pubspec.yaml" ]; then
        log_error "不在Flutter项目根目录中"
        return 1
    fi
    
    # 检查项目名称
    local project_name=$(grep "^name:" pubspec.yaml | cut -d' ' -f2)
    if [[ "$project_name" != "a_dark_room" ]]; then
        log_warning "项目名称不匹配，当前: $project_name"
    fi
    
    log_success "项目环境检查完成"
    return 0
}

# 检查构建工具
check_build_tools() {
    log_debug "检查构建工具..."
    
    local missing_tools=()
    
    # 检查可选的优化工具
    if ! command -v pngquant &> /dev/null; then
        missing_tools+=("pngquant")
    fi
    
    if ! command -v jpegoptim &> /dev/null; then
        missing_tools+=("jpegoptim")
    fi
    
    if ! command -v gzip &> /dev/null; then
        missing_tools+=("gzip")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_warning "缺少可选优化工具: ${missing_tools[*]}"
        log_info "可以通过以下命令安装:"
        log_info "  macOS: brew install pngquant jpegoptim"
        log_info "  Ubuntu: apt-get install pngquant jpegoptim"
    fi
    
    return 0
}

# 错误处理函数
handle_error() {
    local exit_code=$1
    local line_number=$2
    local command="$3"
    
    log_error "脚本在第 $line_number 行执行失败"
    log_error "失败命令: $command"
    log_error "退出代码: $exit_code"
    
    # 清理临时文件
    cleanup_temp_files
    
    exit $exit_code
}

# 清理临时文件
cleanup_temp_files() {
    log_debug "清理临时文件..."
    
    # 清理可能的临时文件
    rm -f /tmp/adarkroom_*.tmp 2>/dev/null || true
    
    return 0
}

# 检查磁盘空间
check_disk_space() {
    local required_space_mb=${1:-1000}  # 默认需要1GB空间
    
    log_debug "检查磁盘空间..."
    
    # 获取当前目录可用空间（MB）
    local available_space
    if command -v df &> /dev/null; then
        # macOS和Linux的df命令略有不同
        if [[ "$OSTYPE" == "darwin"* ]]; then
            available_space=$(df -m . | tail -1 | awk '{print $4}')
        else
            available_space=$(df -BM . | tail -1 | awk '{print $4}' | sed 's/M//')
        fi
        
        if [ "$available_space" -lt "$required_space_mb" ]; then
            log_warning "磁盘空间不足: 可用 ${available_space}MB，需要 ${required_space_mb}MB"
            return 1
        fi
        
        log_debug "磁盘空间充足: ${available_space}MB 可用"
    else
        log_warning "无法检查磁盘空间"
    fi
    
    return 0
}

# 获取项目信息
get_project_info() {
    local info_type="$1"
    
    case "$info_type" in
        "name")
            grep "^name:" pubspec.yaml | cut -d' ' -f2 | tr -d '"'
            ;;
        "version")
            grep "^version:" pubspec.yaml | cut -d' ' -f2 | tr -d '"'
            ;;
        "description")
            grep "^description:" pubspec.yaml | cut -d' ' -f2- | tr -d '"'
            ;;
        *)
            log_error "未知的项目信息类型: $info_type"
            return 1
            ;;
    esac
}

# 显示项目信息
show_project_info() {
    log_info "项目信息:"
    log_info "  名称: $(get_project_info name)"
    log_info "  版本: $(get_project_info version)"
    log_info "  描述: $(get_project_info description)"
}

# 检查网络连接
check_network() {
    log_debug "检查网络连接..."
    
    # 尝试ping Google DNS
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_debug "网络连接正常"
        return 0
    else
        log_warning "网络连接可能有问题"
        return 1
    fi
}

# 格式化文件大小
format_file_size() {
    local size_bytes=$1
    
    if [ "$size_bytes" -lt 1024 ]; then
        echo "${size_bytes}B"
    elif [ "$size_bytes" -lt 1048576 ]; then
        echo "$(( size_bytes / 1024 ))KB"
    elif [ "$size_bytes" -lt 1073741824 ]; then
        echo "$(( size_bytes / 1048576 ))MB"
    else
        echo "$(( size_bytes / 1073741824 ))GB"
    fi
}

# 获取文件大小
get_file_size() {
    local file_path="$1"
    
    if [ -f "$file_path" ]; then
        # macOS和Linux的stat命令不同
        if [[ "$OSTYPE" == "darwin"* ]]; then
            stat -f%z "$file_path"
        else
            stat -c%s "$file_path"
        fi
    else
        echo "0"
    fi
}

# 显示构建统计信息
show_build_stats() {
    local build_dir="$1"
    
    if [ ! -d "$build_dir" ]; then
        log_warning "构建目录不存在: $build_dir"
        return 1
    fi
    
    log_info "构建统计信息:"
    
    # 总大小
    local total_size
    if command -v du &> /dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            total_size=$(du -sh "$build_dir" | cut -f1)
        else
            total_size=$(du -sh "$build_dir" | cut -f1)
        fi
        log_info "  总大小: $total_size"
    fi
    
    # 主要文件大小
    local main_js="$build_dir/main.dart.js"
    if [ -f "$main_js" ]; then
        local main_size=$(get_file_size "$main_js")
        log_info "  main.dart.js: $(format_file_size $main_size)"
    fi
    
    # 文件数量统计
    local file_counts
    file_counts=$(find "$build_dir" -type f | wc -l | tr -d ' ')
    log_info "  文件数量: $file_counts"
    
    return 0
}

# 设置错误处理
setup_error_handling() {
    set -e  # 遇到错误立即退出
    # 注释掉set -u以避免未定义变量警告
    # set -u  # 使用未定义变量时报错
    set -o pipefail  # 管道中任何命令失败都会导致整个管道失败

    # 设置错误陷阱（仅在调试模式下显示详细错误）
    if [[ "${DEBUG:-}" == "true" ]]; then
        trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR
    fi
    trap 'cleanup_temp_files' EXIT
}

# 初始化共享库
init_common_lib() {
    # 设置错误处理
    setup_error_handling
    
    # 显示库信息
    log_debug "A Dark Room 共享函数库已加载"
    
    return 0
}

# 如果直接运行此脚本，显示帮助信息
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "A Dark Room Scripts 共享函数库"
    echo "此文件应该被其他脚本引用，不应直接运行"
    echo ""
    echo "使用方法:"
    echo "  source scripts/lib/common.sh"
    echo "  init_common_lib"
    echo ""
    echo "可用函数:"
    echo "  - 日志函数: log_info, log_success, log_warning, log_error"
    echo "  - 环境检查: check_flutter_environment, check_project_environment"
    echo "  - 项目信息: get_project_info, show_project_info"
    echo "  - 工具函数: format_file_size, show_build_stats"
    exit 1
fi
