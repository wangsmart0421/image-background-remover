# Cloudflare API Token 生成指南

当前提供的Cloudflare Token无效。请按以下步骤生成新的有效Token。

## 🔧 生成步骤

### 步骤1: 登录Cloudflare
1. 访问 https://dash.cloudflare.com/
2. 使用你的账户登录

### 步骤2: 进入API Token页面
1. 点击右上角用户头像
2. 选择 **My Profile**
3. 点击 **API Tokens** 标签页

### 步骤3: 创建新Token
1. 点击 **Create Token**
2. 选择 **Edit Cloudflare Workers** 模板

### 步骤4: 配置权限
确保以下权限被选中：

#### Account 权限
- **Workers Scripts** → **Edit**
- **Workers KV Storage** → **Edit** (可选)
- **Account Settings** → **Read** (可选)

#### Zone 权限 (如果需要自定义域名)
- **Workers Routes** → **Edit**

### 步骤5: 配置资源
1. **Account Resources**: 选择你的账户
2. **Zone Resources**: 选择你的域名（如果需要）

### 步骤6: 生成Token
1. 点击 **Continue to summary**
2. 确认权限配置
3. 点击 **Create Token**

### 步骤7: 复制Token
**重要**: Token只显示一次，请立即复制保存！

## 📋 Token格式
有效的Cloudflare Token格式：
- 长度: 40-50个字符
- 包含字母、数字、下划线
- 示例: `ABC123def456GHI789jkl012MNO345pqr678STU901`

## 🔍 验证Token
生成后，验证Token是否有效：
```bash
curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer YOUR_NEW_TOKEN" \
  -H "Content-Type: application/json"
```

有效响应应包含：
```json
{
  "success": true,
  "result": {
    "id": "...",
    "status": "active"
  }
}
```

## 🚀 使用新Token部署

### 更新环境变量
编辑 `.env` 文件：
```bash
CLOUDFLARE_API_TOKEN=你的新Token
```

### 运行部署
```bash
./deploy.sh all
```

## ⚠️ 安全注意事项

1. **保密性**: Token相当于密码，不要分享或提交到代码仓库
2. **权限最小化**: 只授予必要的权限
3. **定期轮换**: 建议每3-6个月更换一次
4. **监控使用**: 在Cloudflare Dashboard监控Token使用情况

## 🆘 问题排查

### 问题1: Token无效
- 检查Token是否完整复制
- 确保没有多余的空格或换行
- 验证Token是否已激活

### 问题2: 权限不足
- 检查是否缺少Workers Scripts Edit权限
- 确保Account Resources配置正确

### 问题3: Token过期
- 检查Token创建时间
- 生成新的Token替换

## 📞 获取帮助

如果仍有问题：
1. **Cloudflare文档**: https://developers.cloudflare.com/fundamentals/api/
2. **社区支持**: https://community.cloudflare.com/
3. **官方支持**: Cloudflare Dashboard中的支持聊天

## ✅ 完成检查

- [ ] 已登录Cloudflare Dashboard
- [ ] 已创建Edit Cloudflare Workers模板Token
- [ ] 已配置必要权限
- [ ] 已复制并保存Token
- [ ] 已验证Token有效性
- [ ] 已更新.env文件
- [ ] 已测试部署

生成有效Token后，项目即可成功部署到Cloudflare！