#!/bin/bash

# Cloudflare配置检查脚本

echo "========================================="
echo "  Cloudflare配置检查"
echo "========================================="
echo ""

# 检查环境变量
echo "🔍 检查环境变量配置..."
echo "-----------------------------------------"
if [ -f ".env" ]; then
    source .env
    echo "✅ .env文件存在"
    echo "   Remove.bg API密钥: ${REMOVEBG_API_KEY:0:8}..."
    echo "   Cloudflare Account ID: ${CLOUDFLARE_ACCOUNT_ID}"
    echo "   Cloudflare Token长度: ${#CLOUDFLARE_API_TOKEN}"
else
    echo "❌ .env文件不存在"
fi
echo ""

# 检查Remove.bg API
echo "🔍 检查Remove.bg API..."
echo "-----------------------------------------"
if [ -n "$REMOVEBG_API_KEY" ]; then
    echo "测试Remove.bg API连接..."
    response=$(curl -s -X GET "https://api.remove.bg/v1.0/account" \
      -H "X-Api-Key: $REMOVEBG_API_KEY" 2>/dev/null)
    
    if echo "$response" | grep -q "credits"; then
        echo "✅ Remove.bg API连接成功"
        # 解析响应
        credits=$(echo "$response" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('data',{}).get('attributes',{}).get('credits',{}).get('total',0))" 2>/dev/null)
        free_calls=$(echo "$response" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('data',{}).get('attributes',{}).get('api',{}).get('free_calls',0))" 2>/dev/null)
        echo "   总点数: $credits"
        echo "   免费调用: $free_calls/月"
    else
        echo "❌ Remove.bg API连接失败"
        echo "   响应: $response"
    fi
else
    echo "⚠️  REMOVEBG_API_KEY未设置"
fi
echo ""

# 检查Cloudflare Token
echo "🔍 检查Cloudflare Token..."
echo "-----------------------------------------"
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    echo "测试Cloudflare Token验证..."
    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
      -H "Content-Type: application/json" 2>/dev/null)
    
    if echo "$response" | grep -q '"success":true'; then
        echo "✅ Cloudflare Token有效"
        # 解析响应
        status=$(echo "$response" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('result',{}).get('status','unknown'))" 2>/dev/null)
        id=$(echo "$response" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('result',{}).get('id','unknown'))" 2>/dev/null)
        echo "   Token状态: $status"
        echo "   Token ID: ${id:0:8}..."
    else
        echo "❌ Cloudflare Token无效"
        echo "   错误信息:"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    fi
else
    echo "⚠️  CLOUDFLARE_API_TOKEN未设置"
fi
echo ""

# 检查Cloudflare账户
echo "🔍 检查Cloudflare账户..."
echo "-----------------------------------------"
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ] && [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    echo "测试Cloudflare账户访问..."
    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
      -H "Content-Type: application/json" 2>/dev/null)
    
    if echo "$response" | grep -q '"success":true'; then
        echo "✅ Cloudflare账户访问成功"
        name=$(echo "$response" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('result',{}).get('name','unknown'))" 2>/dev/null)
        echo "   账户名称: $name"
    else
        echo "❌ Cloudflare账户访问失败"
    fi
else
    echo "⚠️  缺少账户信息或Token"
fi
echo ""

# 检查本地服务
echo "🔍 检查本地服务..."
echo "-----------------------------------------"
echo "前端服务 (端口3000):"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null | grep -q "200"; then
    echo "✅ 前端服务运行正常"
else
    echo "❌ 前端服务未运行或无法访问"
fi

echo "API服务 (端口8787):"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8787/health 2>/dev/null | grep -q "200"; then
    echo "✅ API服务运行正常"
    echo "   健康检查: $(curl -s http://localhost:8787/health 2>/dev/null)"
else
    echo "❌ API服务未运行或无法访问"
fi
echo ""

# 配置建议
echo "🎯 配置建议"
echo "-----------------------------------------"

# 检查Token格式
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    token_len=${#CLOUDFLARE_API_TOKEN}
    if [ $token_len -lt 40 ] || [ $token_len -gt 50 ]; then
        echo "⚠️  Token长度异常: $token_len 字符 (通常40-50字符)"
    fi
    
    if [[ "$CLOUDFLARE_API_TOKEN" == *" "* ]]; then
        echo "⚠️  Token包含空格，请检查是否正确复制"
    fi
    
    if [[ "$CLOUDFLARE_API_TOKEN" == *$'\n'* ]]; then
        echo "⚠️  Token包含换行符，请检查是否正确复制"
    fi
fi

# 检查Account ID格式
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
    if [[ ! "$CLOUDFLARE_ACCOUNT_ID" =~ ^[a-f0-9]{32}$ ]]; then
        echo "⚠️  Account ID格式异常 (应为32位十六进制)"
    fi
fi

# 检查API密钥格式
if [ -n "$REMOVEBG_API_KEY" ]; then
    if [ ${#REMOVEBG_API_KEY} -lt 20 ]; then
        echo "⚠️  Remove.bg API密钥长度异常"
    fi
fi
echo ""

# 常见问题解决方案
echo "🔧 常见问题解决方案"
echo "-----------------------------------------"
echo "1. Token无效:"
echo "   - 重新生成Token: My Profile → API Tokens → Create Token"
echo "   - 选择 Edit Cloudflare Workers 模板"
echo "   - 确保选中 Workers Scripts → Edit 权限"
echo ""
echo "2. Token验证失败但Dashboard可登录:"
echo "   - 检查Token是否完整复制（无空格/换行）"
echo "   - 检查Token权限是否足够"
echo "   - 尝试生成新Token"
echo ""
echo "3. 账户访问失败:"
echo "   - 确认Account ID正确"
echo "   - 确认Token有账户访问权限"
echo "   - 检查账户是否被暂停"
echo ""

# 下一步行动
echo "🚀 下一步行动"
echo "-----------------------------------------"
echo "根据截图，请检查:"
echo ""
echo "✅ 正确配置:"
echo "   - Token模板: Edit Cloudflare Workers"
echo "   - 权限: Workers Scripts → Edit (必需)"
echo "   - 资源: 选择你的账户"
echo ""
echo "❌ 常见错误:"
echo "   - Token未完整复制（缺少字符）"
echo "   - Token包含多余空格或换行"
echo "   - 权限配置不正确"
echo "   - 未选择账户资源"
echo ""
echo "📋 请提供以下信息:"
echo "   1. 截图中的Token字符串（完整）"
echo "   2. 截图中的权限配置"
echo "   3. 遇到的错误信息"
echo ""

echo "========================================="