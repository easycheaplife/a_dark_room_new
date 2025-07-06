#!/bin/bash

# A Dark Room 微信发布部署脚本
# 自动化构建和部署流程

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载共享函数库
if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
elif [ -f "scripts/lib/common.sh" ]; then
    source "scripts/lib/common.sh"
else
    echo "错误: 无法找到共享函数库 common.sh"
    exit 1
fi

# 初始化共享库
init_common_lib

# 显示帮助信息
show_help() {
    echo "A Dark Room 微信发布部署脚本"
    echo ""
    echo "用法: $0 [选项] [部署目标]"
    echo ""
    echo "部署目标:"
    echo "  build    - 仅构建项目"
    echo "  local    - 本地测试部署"
    echo "  staging  - 测试环境部署"
    echo "  prod     - 生产环境部署"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -c, --clean    构建前清理"
    echo "  -t, --test     部署后运行测试"
    echo "  --server HOST  指定服务器地址"
    echo "  --path PATH    指定服务器路径"
    echo ""
    echo "示例:"
    echo "  $0 build                    # 仅构建项目"
    echo "  $0 local -c -t             # 本地测试部署"
    echo "  $0 prod --server example.com --path /var/www/adarkroom"
}

# 检查环境（使用共享函数）
check_environment() {
    log_info "检查部署环境..."

    # 使用共享函数检查环境
    check_flutter_environment
    check_project_environment

    # 检查构建脚本
    if [ ! -f "scripts/build_web.sh" ]; then
        log_error "构建脚本不存在: scripts/build_web.sh"
        return 1
    fi

    # 检查磁盘空间
    check_disk_space 500  # 需要500MB空间

    log_success "部署环境检查完成"
}

# 构建项目
build_project() {
    local clean_build=$1
    
    log_info "开始构建微信优化版本..."
    
    # 构建参数
    local build_args="wechat -o -r"
    if [ "$clean_build" = true ]; then
        build_args="-c $build_args"
    fi
    
    # 执行构建（使用bash确保环境正确）
    chmod +x scripts/build_web.sh
    bash scripts/build_web.sh $build_args
    
    if [ $? -eq 0 ]; then
        log_success "项目构建完成"
    else
        log_error "项目构建失败"
        exit 1
    fi
}

# 本地测试部署
deploy_local() {
    log_info "启动本地测试服务器..."
    
    # 检查构建结果
    if [ ! -d "build/web" ]; then
        log_error "构建目录不存在，请先运行构建"
        exit 1
    fi
    
    # 启动本地服务器
    cd build/web
    
    # 尝试使用Python服务器
    if command -v python3 &> /dev/null; then
        log_info "使用Python3启动服务器: http://localhost:8000"
        python3 -m http.server 8000
    elif command -v python &> /dev/null; then
        log_info "使用Python启动服务器: http://localhost:8000"
        python -m SimpleHTTPServer 8000
    elif command -v node &> /dev/null; then
        # 使用Node.js serve包
        if command -v npx &> /dev/null; then
            log_info "使用Node.js serve启动服务器: http://localhost:8000"
            npx serve -p 8000
        else
            log_error "无法找到合适的HTTP服务器"
            exit 1
        fi
    else
        log_error "无法找到Python或Node.js来启动本地服务器"
        exit 1
    fi
}

# 远程部署
deploy_remote() {
    local server=$1
    local remote_path=$2
    local env_type=$3
    
    log_info "开始部署到远程服务器: $server"
    
    # 检查构建结果
    if [ ! -d "build/web" ]; then
        log_error "构建目录不存在，请先运行构建"
        exit 1
    fi
    
    # 检查SSH连接
    if ! ssh -o ConnectTimeout=5 "$server" "echo 'SSH连接成功'" &> /dev/null; then
        log_error "无法连接到服务器: $server"
        log_info "请检查:"
        log_info "1. 服务器地址是否正确"
        log_info "2. SSH密钥是否配置"
        log_info "3. 网络连接是否正常"
        exit 1
    fi
    
    # 创建远程目录
    log_info "创建远程目录: $remote_path"
    ssh "$server" "mkdir -p $remote_path"
    
    # 备份现有文件（生产环境）
    if [ "$env_type" = "prod" ]; then
        log_info "备份现有文件..."
        ssh "$server" "
            if [ -d '$remote_path' ]; then
                backup_dir='${remote_path}_backup_$(date +%Y%m%d_%H%M%S)'
                cp -r '$remote_path' \"\$backup_dir\"
                echo '备份保存到: '\"\$backup_dir\"
            fi
        "
    fi
    
    # 上传文件
    log_info "上传文件到服务器..."
    rsync -avz --delete build/web/ "$server:$remote_path/"
    
    # 设置权限
    log_info "设置文件权限..."
    ssh "$server" "
        chown -R www-data:www-data '$remote_path' 2>/dev/null || true
        chmod -R 644 '$remote_path'
        find '$remote_path' -type d -exec chmod 755 {} \;
    "
    
    log_success "部署完成: $server:$remote_path"
}

# 运行测试（使用共享函数）
run_tests() {
    log_info "运行部署后测试..."

    # 检查构建文件
    local required_files=(
        "build/web/index.html"
        "build/web/main.dart.js"
        "build/web/flutter_service_worker.js"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "缺少必要文件: $file"
            return 1
        fi
    done

    # 使用共享函数检查文件大小
    local main_js_size=$(get_file_size "build/web/main.dart.js")
    if [ "$main_js_size" -lt 100000 ]; then
        log_warning "main.dart.js文件可能过小: $(format_file_size $main_js_size)"
    else
        log_info "main.dart.js文件大小: $(format_file_size $main_js_size)"
    fi

    # 显示构建统计
    show_build_stats "build/web"

    log_success "部署测试通过"
}

# 显示部署后信息
show_deployment_info() {
    local deploy_type=$1
    local server=$2
    local remote_path=$3
    
    echo ""
    log_success "🎉 部署完成！"
    echo ""
    
    case $deploy_type in
        "local")
            echo "📱 本地访问地址: http://localhost:8000"
            echo "🔧 微信开发者工具测试: 使用上述地址"
            ;;
        "staging"|"prod")
            echo "🌐 访问地址: https://$server"
            echo "📱 微信测试: 在微信中打开上述地址"
            echo "🔧 服务器路径: $server:$remote_path"
            ;;
    esac
    
    echo ""
    echo "📋 下一步操作:"
    echo "1. 在微信浏览器中测试游戏功能"
    echo "2. 检查移动端界面适配"
    echo "3. 测试分享功能"
    echo "4. 验证存档功能"
    echo ""
    echo "📚 相关文档:"
    echo "- 部署指南: docs/08_deployment/wechat_publishing_guide.md"
    echo "- 问题排查: docs/05_bug_fixes/"
    echo "- 快速导航: docs/QUICK_NAVIGATION.md"
}

# 主函数
main() {
    local deploy_target=""
    local clean_build=false
    local run_test=false
    local server=""
    local remote_path="/var/www/adarkroom"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                clean_build=true
                shift
                ;;
            -t|--test)
                run_test=true
                shift
                ;;
            --server)
                server="$2"
                shift 2
                ;;
            --path)
                remote_path="$2"
                shift 2
                ;;
            build|local|staging|prod)
                deploy_target="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查部署目标
    if [ -z "$deploy_target" ]; then
        log_error "请指定部署目标"
        show_help
        exit 1
    fi
    
    log_info "开始A Dark Room微信部署流程..."
    log_info "部署目标: $deploy_target"
    
    # 执行部署流程
    check_environment
    
    # 构建项目
    if [ "$deploy_target" != "local" ] || [ ! -d "build/web" ]; then
        build_project $clean_build
    fi
    
    # 执行部署
    case $deploy_target in
        "build")
            log_success "构建完成，文件位于: build/web/"
            ;;
        "local")
            if [ "$run_test" = true ]; then
                run_tests
            fi
            deploy_local
            ;;
        "staging"|"prod")
            if [ -z "$server" ]; then
                log_error "远程部署需要指定服务器地址: --server HOST"
                exit 1
            fi
            
            if [ "$run_test" = true ]; then
                run_tests
            fi
            
            deploy_remote "$server" "$remote_path" "$deploy_target"
            show_deployment_info "$deploy_target" "$server" "$remote_path"
            ;;
        *)
            log_error "未知的部署目标: $deploy_target"
            exit 1
            ;;
    esac
    
    if [ "$deploy_target" = "local" ]; then
        show_deployment_info "$deploy_target"
    fi
}

# 运行主函数
main "$@"
