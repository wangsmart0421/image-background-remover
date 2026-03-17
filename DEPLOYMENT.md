# 部署指南

本文档详细说明如何将图片背景去除工具部署到Cloudflare。

## 📋 前置要求

1. **Cloudflare账户** - [注册免费账户](https://dash.cloudflare.com/sign-up)
2. **Remove.bg API密钥** - [获取免费API密钥](https://www.remove.bg/api)
3. **GitHub账户** - 用于代码托管
4. **Node.js 18+** - 本地开发环境

## 🚀 部署步骤

### 步骤1: 准备代码仓库

```bash
# 初始化Git仓库
git init
git add .
git commit -m "Initial commit: Image Background Remover"

# 创建GitHub仓库并推送
git remote add origin https://github.com/your-username/bg-remover-cf.git
git branch -M main
git push -u origin main
```

### 步骤2: 配置Cloudflare Workers

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 进入 **Workers & Pages** → **Create application** → **Worker**
3. 设置Worker名称: `bg-remover-worker`
4. 点击 **Deploy**

### 步骤3: 配置环境变量

在Worker的 **Settings** → **Variables** 中添加:

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `REMOVEBG_API_KEY` | 你的Remove.bg API密钥 | **必需** |
| `MAX_FILE_SIZE` | `10485760` | 最大文件大小（10MB） |
| `ALLOWED_ORIGINS` | 你的前端域名 | 用逗号分隔多个域名 |

### 步骤4: 部署前端到Cloudflare Pages

1. 进入 **Workers & Pages** → **Create application** → **Pages**
2. 连接到你的GitHub仓库
3. 配置构建设置:
   - **Build command**: `cd frontend && npm run build`
   - **Build output directory**: `frontend/build`
   - **Root directory**: `/`
4. 点击 **Save and Deploy**

### 步骤5: 配置自定义域名（可选）

#### Worker自定义域名
1. 在Worker的 **Triggers** → **Custom Domains**
2. 添加自定义域名，如: `api.your-domain.com`
3. 在DNS设置中添加CNAME记录指向Worker

#### Pages自定义域名
1. 在Pages项目的 **Custom domains**
2. 添加你的域名
3. 在DNS设置中添加CNAME记录指向Pages

## 🔧 环境变量详细说明

### Remove.bg API密钥
1. 访问 [Remove.bg API页面](https://www.remove.bg/api)
2. 注册账户并验证邮箱
3. 在Dashboard中获取API密钥
4. 免费计划提供50张/月的额度

### Cloudflare配置
```bash
# 获取Account ID
# 在Cloudflare Dashboard首页查看

# 创建API Token
# 1. 进入 My Profile → API Tokens
# 2. 点击 Create Token
# 3. 选择 Edit Cloudflare Workers 模板
# 4. 保存生成的Token
```

## 📊 监控和日志

### 查看Worker日志
```bash
# 使用Wrangler CLI
npx wrangler tail

# 或在Cloudflare Dashboard查看
# Workers → 你的Worker → Logs
```

### 监控指标
- **请求次数**: Workers Dashboard
- **错误率**: Workers Logs
- **处理时间**: 自定义日志
- **API使用量**: Remove.bg Dashboard

## 🔒 安全配置

### 1. CORS设置
确保 `ALLOWED_ORIGINS` 只包含信任的域名:
```
https://your-app.pages.dev,https://www.your-domain.com
```

### 2. 速率限制
在Cloudflare Dashboard配置:
1. 进入 **Security** → **WAF**
2. 创建速率限制规则
3. 建议: 每个IP 10次/分钟

### 3. API密钥保护
- 永远不要在代码中硬编码API密钥
- 使用Cloudflare环境变量
- 定期轮换密钥

## 💰 成本控制

### 免费额度
- **Cloudflare Workers**: 100,000次请求/天
- **Cloudflare Pages**: 无限请求，10GB带宽
- **Remove.bg API**: 50张图片/月

### 超出免费额度
1. **Remove.bg API**: $0.02 - $0.10/张
2. **Cloudflare Workers**: $5/百万次请求
3. **建议**: 设置使用量提醒

## 🐛 故障排除

### 常见问题

#### 1. Worker返回500错误
```bash
# 检查环境变量
echo $REMOVEBG_API_KEY

# 检查Remove.bg API状态
curl -X GET "https://api.remove.bg/v1.0/account" \
  -H "X-Api-Key: $REMOVEBG_API_KEY"
```

#### 2. CORS错误
- 检查 `ALLOWED_ORIGINS` 是否包含前端域名
- 确保前端使用正确的API地址

#### 3. 图片处理失败
- 检查图片格式是否支持（JPG, PNG, WebP）
- 检查文件大小是否超过限制
- 查看Remove.bg API返回的具体错误

### 调试命令
```bash
# 本地测试Worker
cd worker
npm run dev

# 测试API端点
curl -X POST http://localhost:8787/api/remove-bg \
  -H "Content-Type: application/json" \
  -d '{"image": "data:image/png;base64,..."}'

# 检查部署状态
npx wrangler whoami
npx wrangler deployments list
```

## 🔄 更新部署

### 更新Worker
```bash
cd worker
npm run deploy
```

### 更新前端
```bash
cd frontend
npm run deploy
```

### 回滚部署
```bash
# Worker回滚
npx wrangler rollback

# Pages回滚
# 在Cloudflare Dashboard中选择之前的部署版本
```

## 📞 支持

### 获取帮助
1. **Cloudflare文档**: https://developers.cloudflare.com/
2. **Remove.bg API文档**: https://www.remove.bg/api
3. **GitHub Issues**: 报告问题和功能请求

### 紧急联系
- **Cloudflare支持**: 24/7在线支持
- **Remove.bg支持**: support@remove.bg
- **项目维护者**: 你的联系方式

---

**部署状态检查清单**:
- [ ] GitHub仓库已创建并推送
- [ ] Cloudflare Worker已创建
- [ ] Remove.bg API密钥已配置
- [ ] 前端已部署到Cloudflare Pages
- [ ] 自定义域名已配置（可选）
- [ ] 安全设置已配置
- [ ] 监控已设置
- [ ] 测试通过