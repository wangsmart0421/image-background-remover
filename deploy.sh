#!/bin/bash

# 图片背景去除工具部署脚本
# 使用说明: ./deploy.sh [environment]

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 环境变量文件
ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装，请先安装 $1"
        exit 1
    fi
}

# 检查环境变量文件
check_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        print_warning "未找到 $ENV_FILE 文件"
        if [ -f "$ENV_EXAMPLE" ]; then
            print_info "正在从 $ENV_EXAMPLE 创建 $ENV_FILE..."
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            print_warning "请编辑 $ENV_FILE 文件，填写必要的配置信息"
            exit 1
        else
            print_error "未找到 $ENV_EXAMPLE 文件"
            exit 1
        fi
    fi
    
    # 检查必要的环境变量
    source "$ENV_FILE"
    
    required_vars=(
        "REMOVEBG_API_KEY"
        "CLOUDFLARE_ACCOUNT_ID"
        "CLOUDFLARE_API_TOKEN"
    )
    
    missing_vars=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "以下环境变量未设置: ${missing_vars[*]}"
        print_info "请在 $ENV_FILE 文件中设置这些变量"
        exit 1
    fi
}

# 安装依赖
install_dependencies() {
    print_info "安装项目依赖..."
    
    # 安装根目录依赖
    if [ -f "package.json" ]; then
        npm install
    fi
    
    # 安装前端依赖
    if [ -d "frontend" ]; then
        cd frontend
        npm install
        cd ..
    fi
    
    # 安装Worker依赖
    if [ -d "worker" ]; then
        cd worker
        npm install
        cd ..
    fi
    
    print_success "依赖安装完成"
}

# 构建项目
build_project() {
    print_info "构建项目..."
    
    # 构建前端
    if [ -d "frontend" ]; then
        print_info "构建前端应用..."
        cd frontend
        npm run build
        cd ..
    fi
    
    # 构建Worker
    if [ -d "worker" ]; then
        print_info "构建Worker..."
        cd worker
        npm run build
        cd ..
    fi
    
    print_success "项目构建完成"
}

# 部署到GitHub
deploy_to_github() {
    print_info "部署到GitHub..."
    
    # 检查Git仓库
    if [ ! -d ".git" ]; then
        print_error "当前目录不是Git仓库"
        exit 1
    fi
    
    # 添加所有文件
    git add .
    
    # 提交更改
    commit_message="Deploy: $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_message" || {
        print_warning "没有更改需要提交"
    }
    
    # 推送到远程仓库
    git push origin main
    
    print_success "代码已推送到GitHub"
}

# 部署到Cloudflare Pages
deploy_frontend() {
    print_info "部署前端到Cloudflare Pages..."
    
    if [ ! -d "frontend" ]; then
        print_error "frontend目录不存在"
        exit 1
    fi
    
    cd frontend
    
    # 检查wrangler是否安装
    if ! command -v wrangler &> /dev/null; then
        print_info "安装wrangler..."
        npm install -g wrangler
    fi
    
    # 登录Cloudflare（如果需要）
    if ! wrangler whoami &> /dev/null; then
        print_info "请登录Cloudflare..."
        wrangler login
    fi
    
    # 部署到Pages
    print_info "开始部署..."
    npm run deploy
    
    cd ..
    
    print_success "前端部署完成"
}

# 部署到Cloudflare Workers
deploy_worker() {
    print_info "部署Worker到Cloudflare Workers..."
    
    if [ ! -d "worker" ]; then
        print_error "worker目录不存在"
        exit 1
    fi
    
    cd worker
    
    # 检查wrangler是否安装
    if ! command -v wrangler &> /dev/null; then
        print_info "安装wrangler..."
        npm install -g wrangler
    fi
    
    # 登录Cloudflare（如果需要）
    if ! wrangler whoami &> /dev/null; then
        print_info "请登录Cloudflare..."
        wrangler login
    fi
    
    # 设置环境变量
    print_info "配置环境变量..."
    
    # 从.env文件读取变量
    source "../$ENV_FILE"
    
    # 部署Worker
    print_info "开始部署Worker..."
    
    # 使用wrangler部署
    if [ -f "wrangler.toml" ]; then
        # 部署到生产环境
        wrangler deploy --env production
        
        # 设置环境变量（通过Dashboard或API）
        print_info "请通过Cloudflare Dashboard设置以下环境变量:"
        echo "REMOVEBG_API_KEY=$REMOVEBG_API_KEY"
        echo "MAX_FILE_SIZE=${MAX_FILE_SIZE:-10485760}"
        echo "ALLOWED_ORIGINS=${ALLOWED_ORIGINS:-*}"
    else
        print_error "未找到wrangler.toml配置文件"
        exit 1
    fi
    
    cd ..
    
    print_success "Worker部署完成"
}

# 验证部署
verify_deployment() {
    print_info "验证部署..."
    
    # 获取前端URL（假设从Pages部署）
    if [ -n "$FRONTEND_DOMAIN" ]; then
        frontend_url="https://$FRONTEND_DOMAIN"
    else
        frontend_url="https://your-app.pages.dev"  # 默认值
    fi
    
    # 获取Worker URL
    if [ -n "$WORKER_DOMAIN" ]; then
        worker_url="https://$WORKER_DOMAIN"
    else
        # 尝试从wrangler.toml获取
        if [ -f "worker/wrangler.toml" ]; then
            worker_name=$(grep -E '^name =' worker/wrangler.toml | cut -d'"' -f2)
            worker_url="https://$worker_name.$(wrangler whoami | grep 'account name' | cut -d':' -f2 | xargs).workers.dev"
        else
            worker_url="https://your-worker.workers.dev"
        fi
    fi
    
    print_info "前端URL: $frontend_url"
    print_info "Worker URL: $worker_url"
    
    # 测试健康检查
    print_info "测试API健康检查..."
    if curl -s "$worker_url/health" | grep -q "ok"; then
        print_success "API健康检查通过"
    else
        print_error "API健康检查失败"
    fi
    
    # 测试前端访问
    print_info "测试前端访问..."
    if curl -s -o /dev/null -w "%{http_code}" "$frontend_url" | grep -q "200"; then
        print_success "前端访问正常"
    else
        print_warning "前端访问可能有问题"
    fi
    
    print_success "部署验证完成"
}

# 显示帮助信息
show_help() {
    echo "图片背景去除工具部署脚本"
    echo ""
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  install     安装项目依赖"
    echo "  build       构建项目"
    echo "  github      部署到GitHub"
    echo "  frontend    部署前端到Cloudflare Pages"
    echo "  worker      部署Worker到Cloudflare Workers"
    echo "  verify      验证部署"
    echo "  all         执行完整部署流程"
    echo "  help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 install    # 安装依赖"
    echo "  $0 all        # 完整部署"
}

# 主函数
main() {
    local action=${1:-"help"}
    
    # 检查必要的命令
    check_command "node"
    check_command "npm"
    check_command "git"
    
    case $action in
        "install")
            install_dependencies
            ;;
        "build")
            check_env_file
            build_project
            ;;
        "github")
            deploy_to_github
            ;;
        "frontend")
            check_env_file
            deploy_frontend
            ;;
        "worker")
            check_env_file
            deploy_worker
            ;;
        "verify")
            check_env_file
            verify_deployment
            ;;
        "all")
            print_info "开始完整部署流程..."
            check_env_file
            install_dependencies
            build_project
            deploy_to_github
            deploy_frontend
            deploy_worker
            verify_deployment
            print_success "🎉 部署完成！"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 运行主函数
main "$@"