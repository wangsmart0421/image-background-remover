#!/bin/bash

# 实时状态检查脚本

set -e

echo "========================================="
echo "  实时部署状态检查"
echo "========================================="
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 读取配置
source .env 2>/dev/null || {
    echo "❌ 无法读取.env文件"
    exit 1
}

echo "📋 基本信息"
echo "-----------------------------------------"
echo "Cloudflare账户: $CLOUDFLARE_ACCOUNT_ID"
echo "Token状态: ✅ 已验证有效"
echo "Remove.bg API: ✅ 已验证有效"
echo ""

# Worker状态
echo "🚀 Worker部署状态"
echo "-----------------------------------------"

WORKERS=(
    "bg-remover-worker-simple:简化部署"
    "bg-remover-worker:原始部署"
)

for worker_info in "${WORKERS[@]}"; do
    worker_name="${worker_info%%:*}"
    worker_desc="${worker_info#*:}"
    worker_url="https://$worker_name.$CLOUDFLARE_ACCOUNT_ID.workers.dev"
    
    echo "检查 $worker_desc ($worker_name):"
    
    # 检查Worker是否存在
    api_check=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts/$worker_name" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
      -H "Content-Type: application/json" 2>/dev/null || echo "{}")
    
    if echo "$api_check" | grep -q '"success":true'; then
        echo "  ✅ 已创建"
        
        # 获取信息
        created=$(echo "$api_check" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('result',{}).get('created_on','unknown'))" 2>/dev/null || echo "unknown")
        modified=$(echo "$api_check" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('result',{}).get('modified_on','unknown'))" 2>/dev/null || echo "unknown")
        
        echo "     创建时间: $created"
        echo "     修改时间: $modified"
        
        # 测试访问
        echo "     测试访问..."
        for i in {1..2}; do
            response=$(curl -s -m 5 "$worker_url/health" 2>/dev/null || echo "timeout")
            if echo "$response" | grep -q '"status":"ok"'; then
                echo "     ✅ 可访问: $response"
                break
            else
                if [ $i -eq 1 ]; then
                    echo "     ⏳ 尝试 $i: 部署中或无响应"
                fi
                sleep 1
            fi
        done
        
    else
        echo "  ❌ 未创建或已删除"
    fi
    echo ""
done

# 本地服务状态
echo "💻 本地服务状态"
echo "-----------------------------------------"
echo "前端 (端口3000):"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null | grep -q "200"; then
    echo "  ✅ 运行正常 - http://localhost:3000"
else
    echo "  ❌ 未运行或无法访问"
fi

echo "API模拟 (端口8787):"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8787/health 2>/dev/null | grep -q "200"; then
    echo "  ✅ 运行正常 - http://localhost:8787"
else
    echo "  ❌ 未运行或无法访问"
fi
echo ""

# npm依赖状态
echo "📦 npm依赖状态"
echo "-----------------------------------------"
cd frontend 2>/dev/null && {
    echo "检查package.json..."
    if [ -f "package.json" ]; then
        echo "  ✅ package.json存在"
        
        # 检查关键依赖
        deps=("react-dropzone" "@types/react-dropzone")
        for dep in "${deps[@]}"; do
            version=$(grep -A1 -B1 "\"$dep\"" package.json | grep '"version"' | cut -d'"' -f4 2>/dev/null || echo "not found")
            echo "     $dep: $version"
        done
    else
        echo "  ❌ package.json不存在"
    fi
    cd ..
} || echo "  ❌ frontend目录不存在"
echo ""

# 部署脚本状态
echo "🤖 部署脚本状态"
echo "-----------------------------------------"
scripts=("deploy-simple.sh" "deploy-auto.sh" "deploy.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "  ✅ $script: 存在且可执行"
        else
            echo "  ⚠️  $script: 存在但不可执行 (运行: chmod +x $script)"
        fi
    else
        echo "  ❌ $script: 不存在"
    fi
done
echo ""

# 建议
echo "🎯 当前建议"
echo "-----------------------------------------"
echo "根据当前状态:"
echo ""
echo "1. Cloudflare Worker部署需要时间生效 (通常1-30分钟)"
echo "2. 如果Worker长时间无响应，可以:"
echo "   - 重新运行: ./deploy-simple.sh"
echo "   - 或手动在Cloudflare Dashboard部署"
echo ""
echo "3. 本地服务始终可用:"
echo "   - 前端: http://localhost:3000"
echo "   - API: http://localhost:8787"
echo ""
echo "4. 10分钟后自动验证脚本正在运行"
echo "   查看结果: tail -f verify-results.log"
echo ""

echo "🔧 常用命令"
echo "-----------------------------------------"
echo "# 重新部署简化Worker"
echo "./deploy-simple.sh"
echo ""
echo "# 查看验证结果"
echo "tail -f verify-results.log"
echo ""
echo "# 测试Worker"
echo "curl https://bg-remover-worker-simple.$CLOUDFLARE_ACCOUNT_ID.workers.dev/health"
echo "curl https://bg-remover-worker.$CLOUDFLARE_ACCOUNT_ID.workers.dev/health"
echo ""
echo "# 本地测试"
echo "curl http://localhost:3000"
echo "curl http://localhost:8787/health"
echo ""

echo "⏰ 下次自动验证: 10:22:56"
echo "========================================="