# 配置指南

本文档详细说明如何配置图片背景去除工具的所有组件。

## 📋 配置概览

需要配置的组件：
1. **Remove.bg API** - 背景去除服务
2. **Cloudflare Workers** - 后端API代理
3. **Cloudflare Pages** - 前端托管
4. **GitHub Secrets** - CI/CD自动化
5. **自定义域名** - 生产环境域名

## 🔑 1. Remove.bg API 配置

### 获取API密钥
1. 访问 [Remove.bg API页面](https://www.remove.bg/api)
2. 点击 "Get API Key"
3. 注册账户并验证邮箱
4. 在Dashboard中获取API密钥

### API计划
| 计划 | 每月额度 | 价格 | 适合场景 |
|------|----------|------|----------|
| **免费** | 50张 | $0 | 测试和个人使用 |
| **基础** | 500张 | $9 | 小型项目 |
| **专业** | 5,000张 | $49 | 商业应用 |
| **企业** | 自定义 | 联系销售 | 大规模使用 |

### API限制
- **文件大小**: 最大12MB
- **格式**: JPG, PNG, WebP
- **速率限制**: 免费计划10次/分钟
- **响应时间**: 2-5秒

## ☁️ 2. Cloudflare 配置

### 2.1 创建Cloudflare账户
1. 访问 [Cloudflare](https://dash.cloudflare.com/sign-up)
2. 使用邮箱注册免费账户
3. 验证邮箱地址

### 2.2 获取Account ID
1. 登录Cloudflare Dashboard
2. 在右侧边栏找到 **Account ID**
3. 复制这个ID（格式如：`1234567890abcdef1234567890abcdef`）

### 2.3 创建API Token
1. 进入 **My Profile** → **API Tokens**
2. 点击 **Create Token**
3. 选择 **Edit Cloudflare Workers** 模板
4. 配置权限：
   - **Account** → **Workers Scripts** → **Edit**
   - **Account** → **Workers KV Storage** → **Edit**（可选）
   - **Zone** → **Workers Routes** → **Edit**（如果需要自定义域名）
5. 点击 **Continue to summary**
6. 复制生成的Token（只显示一次）

## 🔧 3. 环境变量配置

### 3.1 本地开发配置
复制 `.env.example` 为 `.env`：

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```env
# ============ Remove.bg API 配置 ============
REMOVEBG_API_KEY=your_actual_removebg_api_key_here

# ============ Cloudflare 配置 ============
CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token

# ============ 应用配置 ============
MAX_FILE_SIZE=10485760  # 10MB
ALLOWED_ORIGINS=http://localhost:3000,https://bg-remover-frontend.pages.dev

# ============ 部署配置 ============
FRONTEND_DOMAIN=bg-remover-frontend.pages.dev
WORKER_DOMAIN=bg-remover-worker.your-account.workers.dev
```

### 3.2 GitHub Secrets 配置
在GitHub仓库中设置以下secrets：

1. 进入仓库 → **Settings** → **Secrets and variables** → **Actions**
2. 点击 **New repository secret**

需要设置的secrets：

| Secret名称 | 值 | 说明 |
|------------|-----|------|
| `REMOVEBG_API_KEY` | 你的Remove.bg API密钥 | **必需** |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API Token | **必需** |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Account ID | **必需** |
| `MAX_FILE_SIZE` | `10485760` | 可选，默认10MB |
| `ALLOWED_ORIGINS` | `*` | 可选，CORS设置 |
| `FRONTEND_URL` | 你的前端URL | 可选，用于通知 |
| `WORKER_URL` | 你的Worker URL | 可选，用于通知 |

### 3.3 Cloudflare Workers 环境变量
在Cloudflare Dashboard中设置：

1. 进入 **Workers & Pages** → 你的Worker
2. 点击 **Settings** → **Variables**
3. 添加以下变量：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `REMOVEBG_API_KEY` | 你的Remove.bg API密钥 | **必需** |
| `MAX_FILE_SIZE` | `10485760` | 最大文件大小 |
| `ALLOWED_ORIGINS` | 你的前端域名 | 用逗号分隔 |

## 🌐 4. 域名配置（可选）

### 4.1 自定义Worker域名
1. 在Cloudflare Dashboard中，进入你的Worker
2. 点击 **Triggers** → **Custom Domains**
3. 点击 **Add Custom Domain**
4. 输入你的域名，如：`api.your-domain.com`
5. 在DNS设置中添加CNAME记录：
   ```
   api.your-domain.com CNAME your-worker.your-account.workers.dev
   ```

### 4.2 自定义Pages域名
1. 在Cloudflare Dashboard中，进入你的Pages项目
2. 点击 **Custom domains**
3. 点击 **Set up a custom domain**
4. 输入你的域名，如：`app.your-domain.com`
5. 在DNS设置中添加CNAME记录：
   ```
   app.your-domain.com CNAME your-project.pages.dev
   ```

## 🚀 5. 部署配置

### 5.1 Worker配置 (`worker/wrangler.toml`)
```toml
name = "bg-remover-worker"
main = "src/index.js"
compatibility_date = "2024-01-01"

[vars]
MAX_FILE_SIZE = "10485760"
ALLOWED_ORIGINS = "https://your-app.pages.dev"

[env.production]
routes = [
  { pattern = "api.your-domain.com/*", custom_domain = true }
]
```

### 5.2 前端配置 (`frontend/.env.production`)
```env
REACT_APP_API_URL=https://api.your-domain.com
REACT_APP_VERSION=1.0.0
REACT_APP_ENV=production
```

## 📊 6. 监控和日志配置

### 6.1 Worker日志
```bash
# 查看实时日志
npx wrangler tail

# 或在Cloudflare Dashboard查看
# Workers → 你的Worker → Logs
```

### 6.2 配置日志推送
1. 进入Worker的 **Settings** → **Logs**
2. 点击 **Configure Logpush**
3. 选择日志目的地（如：Datadog, Splunk等）

### 6.3 监控告警
1. 进入 **Analytics & Logs** → **Workers**
2. 设置告警规则：
   - 错误率 > 5%
   - 请求延迟 > 5秒
   - API配额使用 > 80%

## 🔒 7. 安全配置

### 7.1 CORS安全
```javascript
// 在生产环境中严格限制
const ALLOWED_ORIGINS = [
  'https://your-app.pages.dev',
  'https://www.your-domain.com'
].join(',')
```

### 7.2 速率限制
在Cloudflare Dashboard配置：
1. 进入 **Security** → **WAF**
2. 创建速率限制规则：
   - 路径：`/api/remove-bg`
   - 阈值：10次/分钟
   - 动作：Block

### 7.3 API密钥轮换
建议每3-6个月轮换一次：
1. 生成新的Remove.bg API密钥
2. 更新Cloudflare环境变量
3. 更新GitHub Secrets
4. 验证新密钥工作正常
5. 禁用旧密钥

## 💰 8. 成本优化

### 8.1 免费额度利用
- **Cloudflare Workers**: 100,000次/天
- **Cloudflare Pages**: 无限请求，10GB带宽
- **Remove.bg API**: 50张/月（免费计划）

### 8.2 成本控制策略
1. **文件大小限制**: 限制为5MB（默认10MB）
2. **缓存策略**: 对相同图片使用缓存
3. **请求合并**: 批量处理多个请求
4. **使用量监控**: 设置预算告警

### 8.3 预算估算
| 组件 | 免费额度 | 超出费用 | 月估算（1000张） |
|------|----------|----------|-----------------|
| Remove.bg API | 50张 | $0.02-0.10/张 | $19-95 |
| Cloudflare Workers | 300万次 | $5/百万次 | $0 |
| Cloudflare Pages | 无限 | $0 | $0 |
| **总计** | - | - | **$19-95** |

## 🐛 9. 故障排除

### 9.1 常见问题

#### 问题1: Worker返回500错误
**检查步骤**:
1. 查看Worker日志：`wrangler tail`
2. 检查环境变量是否正确设置
3. 测试Remove.bg API密钥：
   ```bash
   curl -X GET "https://api.remove.bg/v1.0/account" \
     -H "X-Api-Key: $REMOVEBG_API_KEY"
   ```

#### 问题2: CORS错误
**解决方案**:
1. 检查 `ALLOWED_ORIGINS` 包含前端域名
2. 确保前端使用正确的API URL
3. 检查浏览器控制台错误信息

#### 问题3: 图片处理失败
**可能原因**:
1. 图片格式不支持
2. 文件大小超过限制
3. Remove.bg API配额用完
4. 网络连接问题

### 9.2 调试命令
```bash
# 测试本地开发
cd frontend && npm start
cd ../worker && npm run dev

# 测试API端点
curl -X POST http://localhost:8787/api/remove-bg \
  -H "Content-Type: application/json" \
  -d '{"image": "data:image/png;base64,..."}'

# 检查部署状态
npx wrangler whoami
npx wrangler deployments list
```

## 🔄 10. 更新和维护

### 10.1 更新依赖
```bash
# 更新所有依赖
npm update

# 更新前端依赖
cd frontend && npm update

# 更新Worker依赖
cd worker && npm update
```

### 10.2 版本管理
使用语义化版本：
- **主版本**: 不兼容的API更改
- **次版本**: 向后兼容的功能性新增
- **修订版本**: 向后兼容的问题修正

### 10.3 备份策略
1. **代码备份**: GitHub仓库
2. **配置备份**: 导出环境变量
3. **数据备份**: 无持久化数据
4. **文档备份**: 项目文档

## 📞 11. 支持资源

### 官方文档
- [Remove.bg API文档](https://www.remove.bg/api)
- [Cloudflare Workers文档](https://developers.cloudflare.com/workers/)
- [Cloudflare Pages文档](https://developers.cloudflare.com/pages/)

### 社区支持
- [Cloudflare Community](https://community.cloudflare.com/)
- [GitHub Issues](https://github.com/your-username/bg-remover-cf/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/cloudflare-workers)

### 紧急联系
- **Remove.bg支持**: support@remove.bg
- **Cloudflare支持**: 24/7在线聊天
- **项目维护者**: 你的联系方式

---

## ✅ 配置检查清单

- [ ] Remove.bg API密钥已获取
- [ ] Cloudflare账户已创建
- [ ] Cloudflare Account ID已获取
- [ ] Cloudflare API Token已创建
- [ ] 本地 `.env` 文件已配置
- [ ] GitHub Secrets已设置
- [ ] Cloudflare Workers环境变量已配置
- [ ] 自定义域名已设置（可选）
- [ ] 安全配置已完成
- [ ] 监控告警已设置
- [ ] 测试通过

完成所有配置后，运行部署脚本：
```bash
./deploy.sh all
```