import { Router } from 'itty-router'

// 创建路由器
const router = Router()

// CORS 中间件
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
}

// 添加 CORS 头
function addCorsHeaders(response) {
  const headers = new Headers(response.headers)
  Object.entries(corsHeaders).forEach(([key, value]) => {
    headers.set(key, value)
  })
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  })
}

// 处理 OPTIONS 请求
router.options('*', () => {
  return new Response(null, {
    status: 204,
    headers: corsHeaders,
  })
})

// 健康检查端点
router.get('/health', () => {
  return new Response(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }), {
    headers: { 'Content-Type': 'application/json' },
  })
})

// 获取 API 信息
router.get('/info', () => {
  return new Response(
    JSON.stringify({
      service: 'Background Remover API',
      version: '1.0.0',
      provider: 'Remove.bg',
      limits: {
        maxFileSize: parseInt(MAX_FILE_SIZE || '10485760'),
        allowedFormats: ['jpg', 'jpeg', 'png', 'webp'],
      },
    }),
    {
      headers: { 'Content-Type': 'application/json' },
    }
  )
})

// 主 API 端点：背景去除
router.post('/api/remove-bg', async (request) => {
  try {
    // 检查 API 密钥
    if (!REMOVEBG_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'Remove.bg API key not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 解析请求体
    let body
    try {
      body = await request.json()
    } catch (error) {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { image, size = 'auto', format = 'png', crop = false } = body

    // 验证图片数据
    if (!image) {
      return new Response(
        JSON.stringify({ error: 'Image data is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 验证 Base64 数据
    if (!image.startsWith('data:image/')) {
      return new Response(
        JSON.stringify({ error: 'Invalid image format. Expected data URL' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 提取 Base64 部分
    const base64Data = image.split(',')[1]
    if (!base64Data) {
      return new Response(
        JSON.stringify({ error: 'Invalid image data' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 检查文件大小
    const fileSize = Math.ceil(base64Data.length * 0.75) // Base64 近似大小
    const maxSize = parseInt(MAX_FILE_SIZE || '10485760')
    if (fileSize > maxSize) {
      return new Response(
        JSON.stringify({ 
          error: `File too large. Maximum size is ${maxSize / 1024 / 1024}MB`,
          maxSize: maxSize,
          actualSize: fileSize
        }),
        { status: 413, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 调用 Remove.bg API
    const formData = new FormData()
    formData.append('image_file_b64', base64Data)
    formData.append('size', size)
    formData.append('format', format)
    if (crop) {
      formData.append('crop', 'true')
    }

    const removeBgResponse = await fetch('https://api.remove.bg/v1.0/removebg', {
      method: 'POST',
      headers: {
        'X-Api-Key': REMOVEBG_API_KEY,
      },
      body: formData,
    })

    if (!removeBgResponse.ok) {
      const errorText = await removeBgResponse.text()
      console.error('Remove.bg API error:', removeBgResponse.status, errorText)
      
      let errorMessage = 'Failed to remove background'
      if (removeBgResponse.status === 402) {
        errorMessage = 'API quota exceeded'
      } else if (removeBgResponse.status === 429) {
        errorMessage = 'Rate limit exceeded'
      }
      
      return new Response(
        JSON.stringify({ 
          error: errorMessage,
          status: removeBgResponse.status,
          details: errorText
        }),
        { 
          status: removeBgResponse.status,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // 获取处理后的图片
    const resultBlob = await removeBgResponse.blob()
    const resultBuffer = await resultBlob.arrayBuffer()
    const resultBase64 = btoa(
      new Uint8Array(resultBuffer).reduce(
        (data, byte) => data + String.fromCharCode(byte),
        ''
      )
    )

    // 返回结果
    return new Response(
      JSON.stringify({
        success: true,
        image: `data:image/${format};base64,${resultBase64}`,
        format: format,
        size: resultBuffer.byteLength,
        processingTime: removeBgResponse.headers.get('X-RateLimit-Remaining') ? 
          'Processed successfully' : 'Processed'
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-store',
        },
      }
    )

  } catch (error) {
    console.error('Internal server error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
})

// 批量处理端点（可选）
router.post('/api/batch-remove-bg', async (request) => {
  return new Response(
    JSON.stringify({ 
      error: 'Batch processing not implemented in free version',
      upgrade: 'Upgrade to premium for batch processing'
    }),
    { status: 501, headers: { 'Content-Type': 'application/json' } }
  )
})

// 404 处理
router.all('*', () => {
  return new Response(
    JSON.stringify({ 
      error: 'Not found',
      endpoints: [
        'GET /health',
        'GET /info',
        'POST /api/remove-bg',
        'POST /api/batch-remove-bg'
      ]
    }),
    { status: 404, headers: { 'Content-Type': 'application/json' } }
  )
})

// Worker 入口点
export default {
  async fetch(request, env, ctx) {
    // 设置环境变量
    globalThis.REMOVEBG_API_KEY = env.REMOVEBG_API_KEY
    globalThis.MAX_FILE_SIZE = env.MAX_FILE_SIZE
    globalThis.ALLOWED_ORIGINS = env.ALLOWED_ORIGINS

    // 处理请求
    const response = await router.handle(request)
    
    // 添加 CORS 头
    return addCorsHeaders(response)
  }
}