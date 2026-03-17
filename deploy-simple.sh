#!/bin/bash

# 简化部署方案 - 跳过npm构建问题

set -e

echo "简化部署方案..."
source .env

# 直接使用API部署Worker
echo "部署Worker..."
WORKER_NAME="bg-remover-worker-simple"
WORKER_SCRIPT='addEventListener("fetch", event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
  }

  if (request.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders, status: 204 })
  }

  const url = new URL(request.url)
  
  if (url.pathname === "/health") {
    return new Response(JSON.stringify({ 
      status: "ok", 
      service: "Background Remover"
    }), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })
  }

  if (url.pathname === "/info") {
    return new Response(JSON.stringify({
      service: "Background Remover API",
      version: "1.0.0"
    }), { 
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })
  }

  return new Response(JSON.stringify({
    error: "Not found",
    endpoints: ["/health", "/info"]
  }), { 
    status: 404,
    headers: { ...corsHeaders, "Content-Type": "application/json" }
  })
}'

# 使用curl部署
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts/$WORKER_NAME" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/javascript" \
  --data "$WORKER_SCRIPT"

echo "✅ Worker部署完成: https://$WORKER_NAME.$CLOUDFLARE_ACCOUNT_ID.workers.dev"
