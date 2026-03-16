# Image Background Remover - Cloudflare Edition

基于Cloudflare Workers和Remove.bg API的Serverless图片背景去除工具。

## 🌟 特性

- 🚀 **完全Serverless** - 无服务器架构，按需计费
- ⚡ **全球加速** - Cloudflare全球CDN网络
- 🔒 **隐私保护** - 图片仅在内存中处理，不存储
- 🎨 **高质量去除** - 使用Remove.bg专业API
- 📱 **响应式设计** - 支持所有设备
- 🆓 **免费额度** - Cloudflare Workers免费额度充足

## 🏗️ 架构

```
用户浏览器 → Cloudflare Pages (前端) → Cloudflare Worker (API代理) → Remove.bg API
```

### 数据流
1. 用户上传图片 → Base64编码
2. 发送到Cloudflare Worker
3. Worker转发到Remove.bg API
4. Remove.bg处理并返回结果
5. Worker返回处理后的图片
6. 前端显示并允许下载

## 📁 项目结构

```
bg-remover-cf/
├── frontend/                 # React前端应用
│   ├── src/
│   │   ├── components/      # React组件
│   │   ├── pages/          # 页面组件
│   │   └── utils/          # 工具函数
│   └── public/             # 静态资源
├── worker/                  # Cloudflare Worker
│   ├── src/
│   │   └── index.js        # Worker主逻辑
│   └── wrangler.toml       # Worker配置
├── package.json            # 项目配置
└── README.md              # 本文档
```

## 🔧 技术栈

### 前端
- React 18 + TypeScript
- Tailwind CSS
- React Dropzone
- Axios

### 后端
- Cloudflare Workers
- Remove.bg API
- 内存图片处理

### 部署
- Cloudflare Pages (前端)
- Cloudflare Workers (API)
- Cloudflare DNS (域名)

## 🚀 快速开始

### 前置要求
1. Cloudflare账户（免费）
2. Remove.bg API密钥（免费额度）
3. Node.js 18+

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd bg-remover-cf

# 安装依赖
npm install

# 启动前端开发服务器
cd frontend
npm start

# 启动Worker开发服务器
cd ../worker
npm run dev
```

### 部署到生产
```bash
# 部署前端到Cloudflare Pages
cd frontend
npm run deploy

# 部署Worker到Cloudflare Workers
cd ../worker
npm run deploy
```

## ⚙️ 配置

### 环境变量
```bash
# Worker环境变量（通过wrangler.toml或Cloudflare Dashboard设置）
REMOVEBG_API_KEY=your_removebg_api_key
ALLOWED_ORIGINS=https://your-domain.com,http://localhost:3000
MAX_FILE_SIZE=10485760  # 10MB
```

### Remove.bg API配置
1. 注册 https://www.remove.bg/api
2. 获取API密钥
3. 配置到Cloudflare Worker环境变量

## 📈 性能指标

- **处理时间**: 2-5秒（取决于图片大小）
- **并发限制**: Remove.bg API限制 + Cloudflare Workers限制
- **免费额度**: 
  - Cloudflare Workers: 100,000次/天
  - Remove.bg: 50张/月（免费计划）

## 🔒 安全考虑

1. **API密钥保护**: 存储在Cloudflare环境变量中
2. **CORS配置**: 严格限制允许的源
3. **文件大小限制**: 防止大文件攻击
4. **请求频率限制**: 防止滥用
5. **无持久化存储**: 图片不保存，保护隐私

## 💰 成本估算

### 免费计划
- Cloudflare Workers: 免费（10万次/天）
- Cloudflare Pages: 免费
- Remove.bg API: 50张/月免费

### 付费计划（预计）
- Remove.bg API: $0.02 - $0.10/张
- Cloudflare Workers: $5/百万次请求

## 🛠️ 开发指南

### 添加新功能
1. 在前端添加UI组件
2. 在Worker中添加API端点
3. 更新TypeScript类型定义
4. 添加测试用例

### 调试
```bash
# 查看Worker日志
wrangler tail

# 本地测试API
curl -X POST http://localhost:8787/api/remove-bg \
  -H "Content-Type: application/json" \
  -d '{"image": "base64_encoded_image"}'
```

## 📄 许可证

MIT License