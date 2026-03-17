#!/bin/bash

# 直接部署脚本 - 不依赖GitHub Actions
# 使用提供的配置信息直接部署到Cloudflare

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查命令
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装"
        exit 1
    fi
}

# 检查环境变量
check_env() {
    source .env 2>/dev/null || {
        print_error "未找到.env文件"
        exit 1
    }
    
    required_vars=(
        "REMOVEBG_API_KEY"
        "CLOUDFLARE_ACCOUNT_ID"
        "CLOUDFLARE_API_TOKEN"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "环境变量 $var 未设置"
            exit 1
        fi
    done
    
    print_success "环境变量检查通过"
}

# 安装wrangler
install_wrangler() {
    if ! command -v wrangler &> /dev/null; then
        print_info "安装wrangler..."
        npm install -g wrangler
    else
        print_info "wrangler已安装"
    fi
}

# 登录Cloudflare
login_cloudflare() {
    print_info "配置Cloudflare认证..."
    
    # 设置环境变量供wrangler使用
    export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN"
    export CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID"
    
    # 测试认证
    if npx wrangler whoami 2>/dev/null | grep -q "account name"; then
        print_success "Cloudflare认证成功"
    else
        print_warning "无法验证Cloudflare认证，继续部署..."
    fi
}

# 部署Worker
deploy_worker() {
    print_info "部署Cloudflare Worker..."
    
    cd worker
    
    # 安装依赖
    print_info "安装Worker依赖..."
    npm install --no-audit --no-fund
    
    # 创建生产环境配置文件
    cat > wrangler.production.toml << EOF
name = "bg-remover-worker"
main = "src/index.js"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[vars]
REMOVEBG_API_KEY = "$REMOVEBG_API_KEY"
MAX_FILE_SIZE = "${MAX_FILE_SIZE:-10485760}"
ALLOWED_ORIGINS = "${ALLOWED_ORIGINS:-*}"

[[environments]]
name = "production"
EOF
    
    # 部署Worker
    print_info "开始部署Worker..."
    CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" \
    CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID" \
    npx wrangler deploy --env production --config wrangler.production.toml
    
    # 获取Worker URL
    WORKER_URL=$(npx wrangler whoami 2>/dev/null | grep "workers.dev" | head -1 | awk '{print $2}' || echo "")
    if [ -n "$WORKER_URL" ]; then
        print_success "Worker部署完成: $WORKER_URL"
        echo "WORKER_URL=$WORKER_URL" >> ../.env.deployed
    else
        WORKER_URL="https://bg-remover-worker.$CLOUDFLARE_ACCOUNT_ID.workers.dev"
        print_success "Worker部署完成，预计URL: $WORKER_URL"
        echo "WORKER_URL=$WORKER_URL" >> ../.env.deployed
    fi
    
    cd ..
}

# 部署前端
deploy_frontend() {
    print_info "部署前端到Cloudflare Pages..."
    
    cd frontend
    
    # 安装依赖
    print_info "安装前端依赖..."
    npm install --no-audit --no-fund
    
    # 构建
    print_info "构建前端..."
    npm run build
    
    # 创建Pages配置
    print_info "配置Cloudflare Pages..."
    
    # 由于Pages部署需要Git仓库，我们创建一个临时仓库
    temp_dir=$(mktemp -d)
    cp -r build/* "$temp_dir/"
    
    cd "$temp_dir"
    
    # 初始化Git仓库
    git init
    git add .
    git commit -m "Deploy frontend"
    
    # 这里需要手动部署到Pages，因为Pages通常通过Git连接部署
    print_warning "前端需要手动部署到Cloudflare Pages:"
    echo ""
    echo "请按以下步骤操作:"
    echo "1. 访问 https://dash.cloudflare.com/"
    echo "2. 进入 Workers & Pages → Create application → Pages"
    echo "3. 选择 'Direct Upload'"
    echo "4. 上传目录: $temp_dir"
    echo "5. 项目名称: bg-remover-frontend"
    echo "6. 点击 Deploy"
    echo ""
    echo "或者使用GitHub仓库连接自动部署"
    
    # 保存前端构建文件路径
    echo "FRONTEND_BUILD_DIR=$temp_dir" >> ../../.env.deployed
    
    cd ../..
    
    print_info "前端构建完成，等待手动部署"
}

# 测试部署
test_deployment() {
    print_info "测试部署..."
    
    source .env.deployed 2>/dev/null || {
        print_warning "未找到部署信息文件"
        return
    }
    
    if [ -n "$WORKER_URL" ]; then
        print_info "测试Worker健康检查..."
        if curl -s "$WORKER_URL/health" | grep -q "ok"; then
            print_success "Worker健康检查通过"
        else
            print_warning "Worker健康检查失败"
        fi
        
        print_info "测试Remove.bg API连接..."
        if curl -s "$WORKER_URL/info" | grep -q "Remove.bg"; then
            print_success "Remove.bg API连接正常"
        else
            print_warning "Remove.bg API连接测试失败"
        fi
    fi
    
    if [ -n "$FRONTEND_BUILD_DIR" ]; then
        print_info "前端构建文件位于: $FRONTEND_BUILD_DIR"
        print_info "文件数量: $(find "$FRONTEND_BUILD_DIR" -type f | wc -l)"
    fi
}

# 显示部署信息
show_deployment_info() {
    print_success "🎉 部署流程完成！"
    echo ""
    echo "📋 部署摘要:"
    echo ""
    
    source .env.deployed 2>/dev/null || true
    
    if [ -n "$WORKER_URL" ]; then
        echo "✅ Cloudflare Worker:"
        echo "   地址: $WORKER_URL"
        echo "   健康检查: $WORKER_URL/health"
        echo "   API信息: $WORKER_URL/info"
        echo "   背景去除API: $WORKER_URL/api/remove-bg"
        echo ""
    fi
    
    if [ -n "$FRONTEND_BUILD_DIR" ]; then
        echo "✅ 前端构建文件:"
        echo "   目录: $FRONTEND_BUILD_DIR"
        echo "   需要手动上传到Cloudflare Pages"
        echo ""
    fi
    
    echo "🔧 环境变量已配置:"
    echo "   Remove.bg API密钥: ✅ 已设置"
    echo "   Cloudflare Account ID: ✅ 已设置"
    echo "   Cloudflare API Token: ✅ 已设置"
    echo ""
    
    echo "🚀 下一步操作:"
    echo ""
    echo "1. 手动部署前端到Cloudflare Pages:"
    echo "   - 访问 https://dash.cloudflare.com/"
    echo "   - Workers & Pages → Create application → Pages"
    echo "   - 选择 'Direct Upload'"
    echo "   - 上传目录: $FRONTEND_BUILD_DIR"
    echo ""
    echo "2. 测试完整功能:"
    echo "   - 访问部署的前端页面"
    echo "   - 上传测试图片"
    echo "   - 验证背景去除功能"
    echo ""
    echo "3. 配置自定义域名（可选）:"
    echo "   - 在Cloudflare Dashboard配置自定义域名"
    echo "   - 更新CORS设置（如果需要）"
    echo ""
    echo "📞 如有问题，请查看文档或联系支持"
}

# 主函数
main() {
    print_info "开始直接部署流程..."
    
    # 检查命令
    check_command "node"
    check_command "npm"
    check_command "curl"
    
    # 检查环境变量
    check_env
    
    # 安装wrangler
    install_wrangler
    
    # 登录Cloudflare
    login_cloudflare
    
    # 部署Worker
    deploy_worker
    
    # 部署前端
    deploy_frontend
    
    # 测试部署
    test_deployment
    
    # 显示部署信息
    show_deployment_info
}

# 运行主函数
main "$@"