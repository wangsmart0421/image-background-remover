#!/bin/bash

# 10分钟后验证所有问题

set -e

echo "========================================="
echo "  10分钟后问题验证脚本"
echo "========================================="
echo ""
echo "⏰ 开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "⏳ 等待10分钟让Worker完全部署生效..."
echo ""

# 等待10分钟
sleep 600

echo ""
echo "🔍 10分钟已过，开始验证所有问题"
echo "========================================="
echo "验证时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 读取配置
source .env

echo "📋 验证清单"
echo "-----------------------------------------"
echo "1. ✅ Cloudflare Token有效性"
echo "2. ✅ Remove.bg API连接"
echo "3. ⚠️  Worker部署状态"
echo "4. ⚠️  Worker可访问性"
echo "5. ⚠️  npm依赖问题"
echo "6. ⚠️  自动化部署可行性"
echo "-----------------------------------------"
echo ""

# 1. 验证Cloudflare Token
echo "🔑 1. 验证Cloudflare Token"
echo "-----------------------------------------"
token_check=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json")

if echo "$token_check" | grep -q '"success":true'; then
    echo "✅ Token仍然有效"
    status=$(echo "$token_check" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('result',{}).get('status','unknown'))" 2>/dev/null)
    echo "   状态: $status"
else
    echo "❌ Token已失效"
    echo "   响应: $token_check"
fi
echo ""

# 2. 验证Remove.bg API
echo "🖼️ 2. 验证Remove.bg API"
echo "-----------------------------------------"
removebg_check=$(curl -s -X GET "https://api.remove.bg/v1.0/account" \
  -H "X-Api-Key: $REMOVEBG_API_KEY" 2>/dev/null || echo "timeout")

if echo "$removebg_check" | grep -q "credits"; then
    echo "✅ Remove.bg API连接正常"
    credits=$(echo "$removebg_check" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('data',{}).get('attributes',{}).get('credits',{}).get('total',0))" 2>/dev/null || echo "unknown")
    free_calls=$(echo "$removebg_check" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('data',{}).get('attributes',{}).get('api',{}).get('free_calls',0))" 2>/dev/null || echo "unknown")
    echo "   总点数: $credits"
    echo "   免费调用: $free_calls/月"
else
    echo "❌ Remove.bg API连接失败"
    echo "   响应: $removebg_check"
fi
echo ""

# 3. 验证Worker部署状态
echo "🚀 3. 验证Worker部署状态"
echo "-----------------------------------------"

# 检查简化部署的Worker
SIMPLE_WORKER="bg-remover-worker-simple"
SIMPLE_URL="https://$SIMPLE_WORKER.$CLOUDFLARE_ACCOUNT_ID.workers.dev"

echo "检查简化Worker: $SIMPLE_WORKER"
worker_check=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts/$SIMPLE_WORKER" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" 2>/dev/null || echo "{}")

if echo "$worker_check" | grep -q '"success":true'; then
    echo "✅ 简化Worker仍然存在"
    
    # 检查修改时间
    modified=$(echo "$worker_check" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('result',{}).get('modified_on','unknown'))" 2>/dev/null || echo "unknown")
    echo "   最后修改: $modified"
else
    echo "❌ 简化Worker不存在或已删除"
fi
echo ""

# 4. 验证Worker可访问性
echo "🌐 4. 验证Worker可访问性"
echo "-----------------------------------------"

echo "测试简化Worker访问..."
for i in {1..3}; do
    echo "尝试 $i:"
    health_response=$(curl -s -m 10 "$SIMPLE_URL/health" 2>/dev/null || echo "timeout")
    if echo "$health_response" | grep -q '"status":"ok"'; then
        echo "   ✅ 健康检查成功: $health_response"
        SIMPLE_WORKER_ACTIVE=true
        break
    else
        echo "   ❌ 无响应或错误: $health_response"
        sleep 2
    fi
done

if [ "$SIMPLE_WORKER_ACTIVE" = "true" ]; then
    echo "✅ 简化Worker可正常访问"
    
    # 测试API信息
    info_response=$(curl -s -m 10 "$SIMPLE_URL/info" 2>/dev/null || echo "timeout")
    if echo "$info_response" | grep -q '"service":"Background Remover API"'; then
        echo "✅ API信息获取成功"
    else
        echo "⚠️  API信息获取失败: $info_response"
    fi
else
    echo "❌ 简化Worker无法访问（可能部署失败或需要更长时间）"
fi
echo ""

# 检查原始Worker
ORIGINAL_WORKER="bg-remover-worker"
ORIGINAL_URL="https://$ORIGINAL_WORKER.$CLOUDFLARE_ACCOUNT_ID.workers.dev"

echo "检查原始Worker: $ORIGINAL_WORKER"
original_check=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts/$ORIGINAL_WORKER" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" 2>/dev/null || echo "{}")

if echo "$original_check" | grep -q '"success":true'; then
    echo "✅ 原始Worker存在"
    
    # 测试访问
    health_response=$(curl -s -m 10 "$ORIGINAL_URL/health" 2>/dev/null || echo "timeout")
    if echo "$health_response" | grep -q '"status":"ok"'; then
        echo "   ✅ 原始Worker可访问: $health_response"
        ORIGINAL_WORKER_ACTIVE=true
    else
        echo "   ❌ 原始Worker无响应: $health_response"
    fi
else
    echo "❌ 原始Worker不存在"
fi
echo ""

# 5. 验证npm依赖问题
echo "📦 5. 验证npm依赖问题"
echo "-----------------------------------------"

echo "检查前端依赖..."
cd frontend

# 检查package.json
if [ -f "package.json" ]; then
    echo "✅ package.json存在"
    
    # 检查关键依赖版本
    react_dropzone=$(grep -A1 -B1 '"react-dropzone"' package.json | grep '"version"' | cut -d'"' -f4 || echo "not found")
    types_dropzone=$(grep -A1 -B1 '"@types/react-dropzone"' package.json | grep '"version"' | cut -d'"' -f4 || echo "not found")
    
    echo "   react-dropzone版本: $react_dropzone"
    echo "   @types/react-dropzone版本: $types_dropzone"
    
    # 尝试安装测试
    echo "尝试安装测试..."
    npm_test=$(npm install --dry-run 2>&1 | tail -5)
    if echo "$npm_test" | grep -q "ETARGET\|notarget"; then
        echo "❌ npm依赖问题仍然存在"
        echo "   错误: $npm_test"
    else
        echo "✅ npm依赖问题可能已解决"
    fi
else
    echo "❌ package.json不存在"
fi

cd ..
echo ""

# 6. 验证自动化部署可行性
echo "🤖 6. 验证自动化部署可行性"
echo "-----------------------------------------"

echo "检查部署脚本..."
if [ -f "deploy-simple.sh" ] && [ -x "deploy-simple.sh" ]; then
    echo "✅ deploy-simple.sh存在且可执行"
    
    # 测试wrangler
    echo "测试wrangler..."
    wrangler_test=$(npx wrangler whoami 2>&1 | head -5)
    if echo "$wrangler_test" | grep -q "account name"; then
        echo "✅ wrangler配置正常"
    else
        echo "❌ wrangler配置问题: $wrangler_test"
    fi
else
    echo "❌ deploy-simple.sh不存在或不可执行"
fi

if [ -f "deploy-auto.sh" ] && [ -x "deploy-auto.sh" ]; then
    echo "✅ deploy-auto.sh存在且可执行"
else
    echo "❌ deploy-auto.sh不存在或不可执行"
fi
echo ""

# 总结
echo "📊 验证结果总结"
echo "========================================="
echo "验证时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "✅ 应该保持正常的部分:"
echo "   1. Cloudflare Token有效性"
echo "   2. Remove.bg API连接"
echo "   3. wrangler配置"
echo ""

echo "⚠️ 10分钟后可能改善的部分:"
echo "   1. Worker部署状态 (Cloudflare需要时间生效)"
echo "   2. Worker可访问性"
echo ""

echo "❌ 可能仍然存在的问题:"
echo "   1. npm依赖版本问题 (需要手动修复)"
echo "   2. 原始Worker部署问题"
echo ""

echo "🎯 建议下一步:"
if [ "$SIMPLE_WORKER_ACTIVE" = "true" ]; then
    echo "   1. ✅ 简化部署成功！可以在此基础上完善"
    echo "   2. 添加环境变量配置"
    echo "   3. 部署前端到Pages"
else
    echo "   1. ⚠️ Worker部署可能需要更长时间或手动干预"
    echo "   2. 考虑使用Cloudflare Dashboard手动部署"
    echo "   3. 或等待更长时间后重试"
fi
echo ""

echo "🔧 测试命令参考:"
echo "   # 测试简化Worker"
echo "   curl $SIMPLE_URL/health"
echo "   curl $SIMPLE_URL/info"
echo ""
echo "   # 测试原始Worker"
echo "   curl $ORIGINAL_URL/health"
echo ""
echo "   # 重新部署"
echo "   ./deploy-simple.sh"
echo ""

echo "📞 如需进一步协助，请提供:"
echo "   1. 上述测试的具体结果"
echo "   2. Cloudflare Dashboard截图"
echo "   3. 遇到的错误信息"
echo ""
echo "========================================="