#!/bin/bash

# A Dark Room Web构建脚本
# 用于构建优化的Web版本，特别针对微信浏览器

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
if command -v init_common_lib >/dev/null 2>&1; then
    init_common_lib
else
    echo "警告: 共享函数库未正确加载，使用基本功能"
    # 定义基本的日志函数作为后备
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] $1"; }
    log_warning() { echo "[WARNING] $1"; }
    log_error() { echo "[ERROR] $1"; }
    check_flutter_environment() { return 0; }
    check_project_environment() { return 0; }
    check_build_tools() { return 0; }
    get_project_info() { echo ""; }
    show_build_stats() { echo "构建统计信息不可用"; }
fi

# 检查Flutter环境（使用共享函数）
check_flutter() {
    check_flutter_environment
    check_project_environment
    check_build_tools
}

# 清理构建目录
clean_build() {
    log_info "清理构建目录..."
    
    if [ -d "build" ]; then
        rm -rf build
        log_info "已删除build目录"
    fi
    
    flutter clean
    log_success "构建目录清理完成"
}

# 获取依赖
get_dependencies() {
    log_info "获取项目依赖..."

    # 抑制依赖版本警告信息
    flutter pub get --suppress-analytics 2>&1 | \
    grep -v "available)" | \
    grep -v "Try \`flutter pub outdated\`" | \
    grep -v "packages have newer versions" || true

    log_success "依赖获取完成"
}

# 构建Web版本
build_web() {
    local build_mode=$1
    local output_dir=$2
    
    log_info "开始构建Web版本 (模式: $build_mode)..."
    
    local build_args=""
    
    case $build_mode in
        "debug")
            build_args="--debug --dart-define=flutter.web.use_skia=false"
            ;;
        "profile")
            build_args="--profile --dart-define=flutter.web.use_skia=false"
            ;;
        "release")
            build_args="--release --dart-define=flutter.web.use_skia=false"
            ;;
        "wechat")
            build_args="--release --dart-define=flutter.web.use_skia=false --dart-define=flutter.web.auto_detect=false"
            ;;
        *)
            log_error "未知的构建模式: $build_mode"
            exit 1
            ;;
    esac
    
    # 执行构建（抑制详细输出）
    log_info "正在编译，请稍候..."

    # 执行构建并过滤不需要的输出
    flutter build web $build_args --suppress-analytics 2>&1 | \
    grep -v "Font asset.*was tree-shaken" | \
    grep -v "Tree-shaking can be disabled" | \
    grep -v "⡯\|⠭\|⠅\|⢸\|⣇\|⣀\|⡀\|⢹\|⡏\|⠁\|⠈\|⣯\|⣭\|⡅\|⢕\|⡂" | \
    grep -E "(Built build/web|Compiling|Error|Failed|✓)" || true

    # 检查构建是否成功
    if [ ! -d "build/web" ]; then
        log_error "构建失败，build/web目录不存在"
        return 1
    fi
    
    # 如果指定了输出目录，复制构建结果
    if [ -n "$output_dir" ]; then
        log_info "复制构建结果到: $output_dir"
        mkdir -p "$output_dir"
        cp -r build/web/* "$output_dir/"
    fi
    
    log_success "Web版本构建完成"
}

# 优化构建结果
optimize_build() {
    local build_dir="build/web"
    
    log_info "优化构建结果..."
    
    # 检查是否安装了优化工具
    local has_pngquant=false
    local has_jpegoptim=false
    local has_gzip=false
    
    if command -v pngquant &> /dev/null; then
        has_pngquant=true
    fi
    
    if command -v jpegoptim &> /dev/null; then
        has_jpegoptim=true
    fi
    
    if command -v gzip &> /dev/null; then
        has_gzip=true
    fi
    
    # 优化PNG图片
    if [ "$has_pngquant" = true ]; then
        log_info "优化PNG图片..."
        find "$build_dir" -name "*.png" -exec pngquant --force --output {} {} \; 2>/dev/null || true
        log_success "PNG图片优化完成"
    else
        log_warning "pngquant未安装，跳过PNG优化"
    fi
    
    # 优化JPEG图片
    if [ "$has_jpegoptim" = true ]; then
        log_info "优化JPEG图片..."
        find "$build_dir" -name "*.jpg" -exec jpegoptim --max=85 {} \; 2>/dev/null || true
        find "$build_dir" -name "*.jpeg" -exec jpegoptim --max=85 {} \; 2>/dev/null || true
        log_success "JPEG图片优化完成"
    else
        log_warning "jpegoptim未安装，跳过JPEG优化"
    fi
    
    # 压缩文件
    if [ "$has_gzip" = true ]; then
        log_info "压缩静态文件..."
        find "$build_dir" -name "*.js" -exec gzip -f -k {} \; 2>/dev/null || true
        find "$build_dir" -name "*.css" -exec gzip -f -k {} \; 2>/dev/null || true
        find "$build_dir" -name "*.html" -exec gzip -f -k {} \; 2>/dev/null || true
        log_success "文件压缩完成"
    else
        log_warning "gzip未安装，跳过文件压缩"
    fi
    
    log_success "构建结果优化完成"
}

# 生成构建报告（使用共享函数）
generate_report() {
    local build_dir="build/web"
    local report_file="build_report.txt"

    log_info "生成构建报告..."

    {
        echo "A Dark Room Web构建报告"
        echo "========================"
        echo "构建时间: $(date)"
        echo "Flutter版本: $(flutter --version | head -n 1)"
        echo ""

        # 使用共享函数显示项目信息
        echo "项目信息:"
        echo "  名称: $(get_project_info name)"
        echo "  版本: $(get_project_info version)"
        echo ""

        echo "文件大小统计:"
        echo "------------"

        if [ -d "$build_dir" ]; then
            # 使用共享函数显示构建统计
            show_build_stats "$build_dir" | sed 's/^//'

            # 资源文件统计
            echo ""
            echo "资源文件统计:"
            local png_count=$(find "$build_dir" -name "*.png" | wc -l | tr -d ' ')
            local jpg_count=$(find "$build_dir" -name "*.jpg" -o -name "*.jpeg" | wc -l | tr -d ' ')
            local js_count=$(find "$build_dir" -name "*.js" | wc -l | tr -d ' ')
            local css_count=$(find "$build_dir" -name "*.css" | wc -l | tr -d ' ')

            echo "  PNG文件: $png_count 个"
            echo "  JPEG文件: $jpg_count 个"
            echo "  JavaScript文件: $js_count 个"
            echo "  CSS文件: $css_count 个"
        else
            echo "构建目录不存在"
        fi

        echo ""
        echo "构建完成!"
    } > "$report_file"

    # 显示报告内容
    cat "$report_file"

    log_success "构建报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    echo "A Dark Room Web构建脚本"
    echo ""
    echo "用法: $0 [选项] [构建模式]"
    echo ""
    echo "构建模式:"
    echo "  debug    - 调试模式构建"
    echo "  profile  - 性能分析模式构建"
    echo "  release  - 发布模式构建（默认）"
    echo "  wechat   - 微信优化模式构建"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -c, --clean    构建前清理"
    echo "  -o, --optimize 优化构建结果"
    echo "  -r, --report   生成构建报告"
    echo "  --output DIR   指定输出目录"
    echo ""
    echo "示例:"
    echo "  $0 release                    # 发布模式构建"
    echo "  $0 wechat -c -o -r           # 微信优化构建，包含清理、优化和报告"
    echo "  $0 debug --output dist       # 调试构建并输出到dist目录"
}

# 主函数
main() {
    local build_mode="release"
    local do_clean=false
    local do_optimize=false
    local do_report=false
    local output_dir=""
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                do_clean=true
                shift
                ;;
            -o|--optimize)
                do_optimize=true
                shift
                ;;
            -r|--report)
                do_report=true
                shift
                ;;
            --output)
                output_dir="$2"
                shift 2
                ;;
            debug|profile|release|wechat)
                build_mode="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    log_info "开始A Dark Room Web构建流程..."
    log_info "构建模式: $build_mode"
    
    # 执行构建流程
    check_flutter
    
    if [ "$do_clean" = true ]; then
        clean_build
    fi
    
    get_dependencies
    build_web "$build_mode" "$output_dir"
    
    if [ "$do_optimize" = true ]; then
        optimize_build
    fi
    
    if [ "$do_report" = true ]; then
        generate_report
    fi
    
    log_success "构建流程完成!"
    
    # 显示下一步提示
    echo ""
    log_info "下一步:"
    echo "1. 测试构建结果: flutter run -d chrome --web-port 8080"
    echo "2. 部署到服务器: 将build/web目录内容上传到Web服务器"
    echo "3. 配置HTTPS和域名"
    echo "4. 在微信浏览器中测试"
}

# 运行主函数
main "$@"
