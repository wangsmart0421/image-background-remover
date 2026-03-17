#!/bin/bash

# 等待并测试Worker部署

set -e

echo "========================================="
echo "  Worker部署等待与测试"
echo "========================================="
echo "开始时间: $(date '+%H:%M:%S')"
echo ""

source .env

WORKER_NAME="bg-remover-worker-simple"
WORKER_URL="https://$WORKER_NAME.$CLOUDFLARE_ACCOUNT_ID.workers.dev"

echo "📋 测试信息"
echo "-----------------------------------------"
echo "Worker: $WORKER_NAME"
echo "URL: $WORKER_URL"
echo ""

echo "⏳ 等待部署生效 (Cloudflare通常需要1-5分钟)..."
echo ""

# 每30秒测试一次，最多10次（5分钟）
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "尝试 $attempt/$max_attempts ($(date '+%H:%M:%S')):"
    
    # 测试健康检查
    response=$(curl -s -m 10 "$WORKER_URL/health" 2>/dev/null || echo "timeout")
    
    if echo "$response" | grep -q '"status":"ok"'; then
        echo "  ✅ Worker已生效！"
        echo "  响应: $response"
        echo ""
        
        # 测试API信息
        echo "测试API信息端点..."
        info_response=$(curl -s -m 10 "$WORKER_URL/info" 2>/dev/null || echo "timeout")
        if echo "$info_response" | grep -q '"service":"Background Remover API"'; then
            echo "  ✅ API信息正常: $info_response"
        else
            echo "  ⚠️  API信息异常: $info_response"
        fi
        
        echo ""
        echo "🎉 Worker部署成功并已生效！"
        echo "   健康检查: $WORKER_URL/health"
        echo "   API信息: $WORKER_URL/info"
        
        # 保存成功状态
        echo "WORKER_ACTIVE=true" > .deployment-status
        echo "WORKER_URL=$WORKER_URL" >> .deployment-status
        echo "ACTIVATION_TIME=$(date '+%Y-%m-%d %H:%M:%S')" >> .deployment-status
        
        exit 0
    else
        echo "  ⏳ 尚未生效: $response"
        
        # 如果还有尝试次数，等待
        if [ $attempt -lt $max_attempts ]; then
            echo "  等待30秒后重试..."
            sleep 30
        fi
    fi
    
    attempt=$((attempt + 1))
done

echo ""
echo "❌ 经过5分钟等待，Worker仍未生效"
echo "可能原因:"
echo "1. Cloudflare部署需要更长时间 (有时需要10-15分钟)"
echo "2. Worker代码可能有错误"
echo "3. 网络或权限问题"
echo ""
echo "🔧 建议操作:"
echo "1. 等待更长时间后重试"
echo "2. 检查Cloudflare Dashboard中的Worker状态"
echo "3. 查看Worker日志: npx wrangler tail (如果配置了wrangler)"
echo "4. 尝试手动在Dashboard部署"
echo ""
echo "📞 如需帮助，请提供:"
echo "- Cloudflare Dashboard截图"
echo "- 具体的错误信息"
echo "- 部署时间"

exit 1