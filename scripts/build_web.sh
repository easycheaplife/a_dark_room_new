#!/bin/bash

# A Dark Room Web构建脚本
# 用于构建优化的Web版本，特别针对微信浏览器

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Flutter环境
check_flutter() {
    log_info "检查Flutter环境..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter未安装或不在PATH中"
        exit 1
    fi
    
    local flutter_version=$(flutter --version | head -n 1)
    log_info "Flutter版本: $flutter_version"
    
    # 检查Flutter Web支持
    if ! flutter config | grep -q "enable-web: true"; then
        log_warning "Flutter Web支持未启用，正在启用..."
        flutter config --enable-web
    fi
    
    log_success "Flutter环境检查完成"
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
    
    flutter pub get
    
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
            build_args="--debug --web-renderer html"
            ;;
        "profile")
            build_args="--profile --web-renderer html"
            ;;
        "release")
            build_args="--release --web-renderer html --dart-define=flutter.web.use_skia=false"
            ;;
        "wechat")
            build_args="--release --web-renderer html --dart-define=flutter.web.use_skia=false --dart-define=flutter.web.auto_detect=false"
            ;;
        *)
            log_error "未知的构建模式: $build_mode"
            exit 1
            ;;
    esac
    
    # 执行构建
    flutter build web $build_args
    
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
        find "$build_dir" -name "*.js" -exec gzip -k {} \;
        find "$build_dir" -name "*.css" -exec gzip -k {} \;
        find "$build_dir" -name "*.html" -exec gzip -k {} \;
        log_success "文件压缩完成"
    else
        log_warning "gzip未安装，跳过文件压缩"
    fi
    
    log_success "构建结果优化完成"
}

# 生成构建报告
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
        echo "文件大小统计:"
        echo "------------"
        
        if [ -d "$build_dir" ]; then
            # 总大小
            local total_size=$(du -sh "$build_dir" | cut -f1)
            echo "总大小: $total_size"
            echo ""
            
            # 主要文件大小
            echo "主要文件:"
            if [ -f "$build_dir/main.dart.js" ]; then
                ls -lh "$build_dir/main.dart.js" | awk '{print "  main.dart.js: " $5}'
            fi
            if [ -f "$build_dir/flutter_service_worker.js" ]; then
                ls -lh "$build_dir/flutter_service_worker.js" | awk '{print "  flutter_service_worker.js: " $5}'
            fi
            if [ -f "$build_dir/flutter.js" ]; then
                ls -lh "$build_dir/flutter.js" | awk '{print "  flutter.js: " $5}'
            fi
            echo ""
            
            # 资源文件统计
            echo "资源文件统计:"
            local png_count=$(find "$build_dir" -name "*.png" | wc -l)
            local jpg_count=$(find "$build_dir" -name "*.jpg" -o -name "*.jpeg" | wc -l)
            local js_count=$(find "$build_dir" -name "*.js" | wc -l)
            local css_count=$(find "$build_dir" -name "*.css" | wc -l)
            
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
