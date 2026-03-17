# 🖼️ Image Background Remover - Cloudflare Edition

基于Cloudflare Workers和Remove.bg API的Serverless图片背景去除工具。完全免费，全球加速，隐私保护。

## ✨ 特性

- 🚀 **完全Serverless** - 无服务器架构，按需计费
- ⚡ **全球加速** - Cloudflare全球CDN网络
- 🔒 **隐私保护** - 图片仅在内存中处理，不存储
- 🎨 **高质量去除** - 使用Remove.bg专业API
- 🌐 **双语界面** - 支持English/中文实时切换
- 📱 **响应式设计** - 支持所有设备
- 🆓 **免费额度** - Cloudflare免费，Remove.bg 50张/月免费

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

## 🚀 快速部署

### 前置要求
1. **Remove.bg API密钥** - [免费获取](https://www.remove.bg/api)
2. **Cloudflare账户** - [免费注册](https://dash.cloudflare.com/sign-up)
3. **GitHub账户** - 代码托管和CI/CD

### 一键部署
1. **Fork此仓库**到你的GitHub账户
2. **配置GitHub Secrets**:
   - `REMOVEBG_API_KEY`: 你的Remove.bg API密钥
   - `CLOUDFLARE_API_TOKEN`: Cloudflare API Token
   - `CLOUDFLARE_ACCOUNT_ID`: Cloudflare Account ID
3. **推送代码**到main分支，GitHub Actions会自动部署

### 手动部署
```bash
# 克隆项目
git clone https://github.com/your-username/bg-remover-cf.git
cd bg-remover-cf

# 配置环境变量
cp .env.example .env
# 编辑.env文件，填入你的配置

# 一键部署
chmod +x deploy.sh
./deploy.sh all
```

## 📁 项目结构

```
bg-remover-cf/
├── frontend/                 # React前端应用
│   ├── src/
│   │   ├── components/      # React组件
│   │   └── utils/          # API工具函数
│   └── public/             # 静态资源（双语界面）
├── worker/                  # Cloudflare Worker
│   ├── src/
│   │   └── index.js        # Worker主逻辑
│   └── wrangler.toml       # Worker配置
├── .github/workflows/      # GitHub Actions
│   └── deploy.yml          # 自动化部署
├── scripts/                # 部署脚本
│   └── deploy.sh           # 一键部署脚本
└── docs/                   # 完整文档
```

## 🔧 技术栈

### 前端
- **React 18** + **TypeScript**
- **Tailwind CSS** - 现代化UI
- **React Dropzone** - 文件上传
- **Axios** - HTTP客户端

### 后端
- **Cloudflare Workers** - Serverless运行时
- **Remove.bg API** - 专业背景去除
- **itty-router** - 轻量级路由

### 部署
- **Cloudflare Pages** - 前端托管
- **Cloudflare Workers** - API服务
- **GitHub Actions** - CI/CD自动化

## ⚙️ 配置

### 环境变量
```bash
# Remove.bg API配置
REMOVEBG_API_KEY=your_removebg_api_key

# Cloudflare配置
CLOUDFLARE_ACCOUNT_ID=your_account_id
CLOUDFLARE_API_TOKEN=your_api_token

# 应用配置
MAX_FILE_SIZE=10485760  # 10MB
ALLOWED_ORIGINS=http://localhost:3000,https://your-app.pages.dev
```

### Remove.bg API计划
| 计划 | 每月额度 | 价格 | 适合场景 |
|------|----------|------|----------|
| **免费** | 50张 | $0 | 测试和个人使用 |
| **基础** | 500张 | $9 | 小型项目 |
| **专业** | 5,000张 | $49 | 商业应用 |

## 📈 性能指标

- **处理时间**: 2-5秒（取决于图片大小）
- **并发能力**: Cloudflare Workers自动伸缩
- **可用性**: 99.9%+（Cloudflare全球网络）
- **免费额度**: 
  - Cloudflare Workers: 100,000次/天
  - Cloudflare Pages: 无限请求
  - Remove.bg API: 50张/月

## 🔒 安全特性

1. **API密钥保护** - 存储在环境变量中
2. **CORS限制** - 严格限制允许的源
3. **文件验证** - 验证格式和大小
4. **无持久化** - 图片不保存，保护隐私
5. **速率限制** - 防止滥用

## 💰 成本估算

### 免费计划（足够个人使用）
- **Cloudflare Workers**: 100,000次/天免费
- **Cloudflare Pages**: 完全免费
- **Remove.bg API**: 50张/月免费

### 付费估算（1000张/月）
- Remove.bg API: $19-95
- Cloudflare Workers: $0（在免费额度内）
- **总计**: $19-95/月

## 🌐 访问地址

部署完成后，你可以访问：

- **前端界面**: `https://bg-remover-frontend.pages.dev`
- **API服务**: `https://bg-remover-worker.[account-id].workers.dev`

### 自定义域名（推荐）
- **前端**: `https://app.your-domain.com`
- **API**: `https://api.your-domain.com`

## 🎨 界面功能

### 主要功能
1. **图片上传** - 拖拽或点击上传
2. **实时预览** - 上传后立即预览
3. **处理选项**:
   - 输出格式: PNG, JPG, ZIP
   - 图片尺寸: 自动, 预览, 小, 中, 大, HD, 4K
   - 裁剪选项: 自动裁剪到主体
4. **处理状态** - 进度条和状态提示
5. **结果操作** - 下载, 复制, 分享

### 双语支持
- 右上角English/中文切换
- 智能语言检测
- 本地存储用户偏好
- 所有界面文本双语化

## 📊 监控和日志

### 内置监控
1. **健康检查**: `/health` 端点
2. **API信息**: `/info` 端点
3. **错误日志**: Cloudflare Workers日志
4. **使用统计**: Remove.bg Dashboard

### 查看日志
```bash
# 查看Worker日志
npx wrangler tail

# 或在Cloudflare Dashboard查看
# Workers → 你的Worker → Logs
```

## 🐛 故障排除

### 常见问题

#### 1. Worker返回500错误
```bash
# 检查环境变量
echo $REMOVEBG_API_KEY

# 测试Remove.bg API
curl -X GET "https://api.remove.bg/v1.0/account" \
  -H "X-Api-Key: $REMOVEBG_API_KEY"
```

#### 2. CORS错误
- 检查 `ALLOWED_ORIGINS` 是否包含前端域名
- 确保前端使用正确的API地址

#### 3. 图片处理失败
- 检查图片格式是否支持（JPG, PNG, WebP）
- 检查文件大小是否超过10MB
- 查看Remove.bg API返回的具体错误

### 调试命令
```bash
# 本地开发
cd frontend && npm start
cd ../worker && npm run dev

# 测试API
curl -X POST http://localhost:8787/api/remove-bg \
  -H "Content-Type: application/json" \
  -d '{"image": "data:image/png;base64,..."}'
```

## 🔄 更新和维护

### 更新依赖
```bash
# 更新所有依赖
npm update

# 更新前端
cd frontend && npm update

# 更新Worker
cd worker && npm update
```

### 部署更新
```bash
# 使用部署脚本
./deploy.sh all

# 或推送到GitHub，GitHub Actions会自动部署
git add .
git commit -m "Update: description"
git push origin main
```

## 📞 支持

### 文档
- [部署指南](DEPLOYMENT.md) - 详细部署步骤
- [配置指南](CONFIGURATION.md) - 完整配置说明
- [项目总结](PROJECT_SUMMARY.md) - 项目概述

### 问题反馈
1. **GitHub Issues** - 功能请求和Bug报告
2. **文档** - 查看常见问题解答
3. **社区** - Cloudflare Community

### 紧急联系
- **Remove.bg支持**: support@remove.bg
- **Cloudflare支持**: 24/7在线聊天
- **项目维护者**: 你的联系方式

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎贡献代码、报告问题或提出功能建议！

1. Fork项目仓库
2. 创建功能分支
3. 提交Pull Request
4. 等待代码审查

---

## 🎯 立即开始

### 选项1: 使用GitHub Actions（推荐）
1. Fork此仓库
2. 配置GitHub Secrets
3. 推送代码，自动部署

### 选项2: 手动部署
1. 克隆项目
2. 配置环境变量
3. 运行部署脚本

### 选项3: 使用现有部署
如果你已经提供了配置信息，项目已准备就绪，可以立即部署！

**部署命令**:
```bash
cd bg-remover-cf
./deploy.sh all
```

项目已完全准备就绪，可以立即部署到生产环境！