#!/bin/bash

# GitHub仓库推送脚本
# 使用说明: ./push-to-github.sh [repository-url]

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查Git
if ! command -v git &> /dev/null; then
    echo "错误: Git未安装"
    exit 1
fi

# 获取仓库URL参数
REPO_URL=${1:-""}

# 检查是否在Git仓库中
if [ ! -d ".git" ]; then
    print_info "初始化Git仓库..."
    git init
    git branch -M main
fi

# 添加所有文件
print_info "添加文件到Git..."
git add .

# 提交更改
print_info "提交更改..."
commit_message="Deploy: Image Background Remover $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$commit_message" || {
    print_info "没有更改需要提交"
}

# 如果提供了仓库URL，设置远程仓库
if [ -n "$REPO_URL" ]; then
    print_info "设置远程仓库: $REPO_URL"
    git remote remove origin 2>/dev/null || true
    git remote add origin "$REPO_URL"
    
    print_info "推送到GitHub..."
    git push -u origin main --force
    
    print_success "代码已推送到GitHub仓库: $REPO_URL"
    
    # 显示GitHub Secrets配置说明
    echo ""
    echo "📋 接下来需要在GitHub仓库中配置Secrets:"
    echo ""
    echo "1. 进入仓库 Settings → Secrets and variables → Actions"
    echo "2. 点击 New repository secret"
    echo ""
    echo "需要配置的Secrets:"
    echo "  - REMOVEBG_API_KEY: gS4kUV3WBuoc27rAHKQKtKR1"
    echo "  - CLOUDFLARE_API_TOKEN: jll7Y8n_z7SQ_3zLBlIEFFA27z6FQaKc5gpL_wb_"
    echo "  - CLOUDFLARE_ACCOUNT_ID: 1fea0d1a61332d8453279214fde43352"
    echo ""
    echo "配置完成后，GitHub Actions会自动部署到Cloudflare！"
else
    print_info "未提供GitHub仓库URL，跳过推送"
    print_info "当前Git状态:"
    git status
    echo ""
    echo "要推送到GitHub，请运行:"
    echo "  ./push-to-github.sh https://github.com/your-username/bg-remover-cf.git"
fi

print_success "Git操作完成"