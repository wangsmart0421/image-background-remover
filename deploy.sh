#!/bin/bash

# Cloudflare 部署脚本
# 用法: ./deploy.sh [frontend|worker|all]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 开始部署 Background Remover...${NC}"

# 检查参数
DEPLOY_TARGET="${1:-all}"

# 检查必要的环境变量
check_env() {
  echo -e "${YELLOW}检查环境变量...${NC}"
  
  if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    echo -e "${RED}错误: CLOUDFLARE_ACCOUNT_ID 未设置${NC}"
    echo "请设置环境变量: export CLOUDFLARE_ACCOUNT_ID=your_account_id"
    exit 1
  fi
  
  if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo -e "${RED}错误: CLOUDFLARE_API_TOKEN 未设置${NC}"
    echo "请设置环境变量: export CLOUDFLARE_API_TOKEN=your_api_token"
    exit 1
  fi
  
  if [ -z "$REMOVEBG_API_KEY" ]; then
    echo -e "${YELLOW}警告: REMOVEBG_API_KEY 未设置${NC}"
    echo "Worker 将无法正常工作，请在 Cloudflare Dashboard 中设置"
  fi
  
  echo -e "${GREEN}✓ 环境变量检查通过${NC}"
}

# 部署前端
deploy_frontend() {
  echo -e "${YELLOW}部署前端到 Cloudflare Pages...${NC}"
  
  cd frontend
  
  # 安装依赖
  echo "安装前端依赖..."
  npm install
  
  # 构建
  echo "构建前端应用..."
  npm run build
  
  # 部署到 Cloudflare Pages
  echo "部署到 Cloudflare Pages..."
  wrangler pages deploy ./build --project-name=bg-remover
  
  cd ..
  
  echo -e "${GREEN}✓ 前端部署完成${NC}"
}

# 部署 Worker
deploy_worker() {
  echo -e "${YELLOW}部署 Worker 到 Cloudflare Workers...${NC}"
  
  cd worker
  
  # 安装依赖
  echo "安装 Worker 依赖..."
  npm install
  
  # 更新 wrangler.toml 中的 Account ID
  echo "更新 Worker 配置..."
  sed -i "s/YOUR_CLOUDFLARE_ACCOUNT_ID/$CLOUDFLARE_ACCOUNT_ID/g" wrangler.toml
  
  # 部署 Worker
  echo "部署 Worker..."
  wrangler deploy
  
  cd ..
  
  echo -e "${GREEN}✓ Worker 部署完成${NC}"
}

# 显示部署信息
show_info() {
  echo ""
  echo -e "${GREEN}🎉 部署完成！${NC}"
  echo ""
  echo "应用信息："
  echo "----------------------------------------"
  
  # 获取 Worker 信息
  if command -v wrangler &> /dev/null; then
    echo "Worker URL:"
    wrangler whoami | grep "workers.dev" || echo "  (运行 'wrangler whoami' 查看)"
  fi
  
  echo ""
  echo "下一步："
  echo "1. 在 Cloudflare Dashboard 中设置环境变量："
  echo "   - REMOVEBG_API_KEY: 你的 Remove.bg API 密钥"
  echo "   - ALLOWED_ORIGINS: 允许的域名"
  echo ""
  echo "2. 配置自定义域名（可选）："
  echo "   - 在 wrangler.toml 中更新域名配置"
  echo "   - 在 Cloudflare DNS 中添加记录"
  echo ""
  echo "3. 测试应用："
  echo "   - 访问前端页面"
  echo "   - 上传图片测试背景去除"
  echo ""
  echo "4. 监控和日志："
  echo "   - 使用 'wrangler tail' 查看实时日志"
  echo "   - 在 Cloudflare Dashboard 查看分析"
}

# 主函数
main() {
  check_env
  
  case $DEPLOY_TARGET in
    frontend)
      deploy_frontend
      ;;
    worker)
      deploy_worker
      ;;
    all)
      deploy_frontend
      deploy_worker
      ;;
    *)
      echo -e "${RED}错误: 未知的部署目标 '$DEPLOY_TARGET'${NC}"
      echo "用法: $0 [frontend|worker|all]"
      exit 1
      ;;
  esac
  
  show_info
}

# 运行主函数
main