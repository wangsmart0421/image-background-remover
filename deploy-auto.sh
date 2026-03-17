#!/bin/bash

# 自动化部署脚本

set -e

echo "开始自动化部署..."

# 读取配置
source .env

# 1. 构建前端
echo "构建前端..."
cd frontend
npm ci
npm run build
cd ..

# 2. 部署Worker
echo "部署Worker..."
cd worker

# 创建wrangler配置
cat > wrangler.toml << WRANGLER_EOF
name = "bg-remover-worker"
main = "src/index.js"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[vars]
REMOVEBG_API_KEY = "$REMOVEBG_API_KEY"
MAX_FILE_SIZE = "10485760"
ALLOWED_ORIGINS = "*"

[[environments]]
name = "production"
WRANGLER_EOF

# 安装依赖并部署
npm ci
npx wrangler deploy --env production

cd ..

# 3. 部署前端到Pages
echo "部署前端到Cloudflare Pages..."
cd frontend
npx wrangler pages deploy ./build --project-name=bg-remover-frontend
cd ..

echo "✅ 自动化部署完成！"
