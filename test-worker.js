/**
 * 本地测试Worker API
 * 这个脚本模拟Cloudflare Worker的功能，让你在本地测试API
 */

const http = require('http');
const url = require('url');

const PORT = 8787;

// 模拟的API响应
const mockResponses = {
  '/health': {
    status: 200,
    data: { status: 'ok', timestamp: new Date().toISOString(), service: 'Background Remover API' }
  },
  '/info': {
    status: 200,
    data: {
      service: 'Background Remover API',
      version: '1.0.0',
      provider: 'Remove.bg (模拟)',
      limits: {
        maxFileSize: 10485760,
        allowedFormats: ['jpg', 'jpeg', 'png', 'webp']
      },
      endpoints: [
        'GET /health',
        'GET /info', 
        'POST /api/remove-bg'
      ]
    }
  },
  '/api/remove-bg': {
    status: 200,
    data: {
      success: true,
      message: '背景去除成功（模拟）',
      image: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      format: 'png',
      size: 1234,
      processingTime: '1.2s',
      note: '这是模拟响应。在生产环境中，这里会是真实的去除背景后的图片。'
    }
  }
};

// 创建HTTP服务器
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  
  // 设置CORS头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Max-Age', '86400');
  
  // 处理OPTIONS请求
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }
  
  console.log(`[${new Date().toISOString()}] ${req.method} ${pathname}`);
  
  // 查找对应的响应
  let response = mockResponses[pathname];
  
  if (!response) {
    // 404处理
    response = {
      status: 404,
      data: {
        error: 'Not found',
        path: pathname,
        availableEndpoints: Object.keys(mockResponses)
      }
    };
  }
  
  // 处理POST请求
  if (req.method === 'POST' && pathname === '/api/remove-bg') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        console.log('收到图片处理请求:', {
          hasImage: !!data.image,
          format: data.format || 'auto',
          size: data.size || 'auto'
        });
        
        // 模拟处理延迟
        setTimeout(() => {
          sendResponse(res, response);
        }, 1000);
      } catch (error) {
        sendResponse(res, {
          status: 400,
          data: { error: 'Invalid JSON', message: error.message }
        });
      }
    });
  } else {
    // GET请求直接响应
    sendResponse(res, response);
  }
});

function sendResponse(res, response) {
  res.writeHead(response.status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(response.data, null, 2));
}

// 启动服务器
server.listen(PORT, () => {
  console.log('='.repeat(60));
  console.log('🚀 背景去除API模拟服务器');
  console.log('='.repeat(60));
  console.log(`📍 本地地址: http://localhost:${PORT}`);
  console.log(`🌐 API端点:`);
  console.log(`   GET  http://localhost:${PORT}/health`);
  console.log(`   GET  http://localhost:${PORT}/info`);
  console.log(`   POST http://localhost:${PORT}/api/remove-bg`);
  console.log('');
  console.log('📋 测试命令:');
  console.log(`   curl http://localhost:${PORT}/health`);
  console.log(`   curl -X POST http://localhost:${PORT}/api/remove-bg \\`);
  console.log(`     -H "Content-Type: application/json" \\`);
  console.log(`     -d '{"image":"data:image/png;base64,..."}'`);
  console.log('');
  console.log('🔧 这是模拟服务器，用于演示API接口。');
  console.log('   在生产环境中，这将连接到真实的Remove.bg API。');
  console.log('='.repeat(60));
  console.log('🔄 服务器运行中... 按 Ctrl+C 停止');
});

// 优雅关闭
process.on('SIGINT', () => {
  console.log('\n👋 服务器已停止');
  process.exit(0);
});