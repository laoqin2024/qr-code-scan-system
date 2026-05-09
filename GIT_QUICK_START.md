# 🚀 Git 推送快速指南

## 📝 操作步骤

### 1️⃣ 在 GitHub 创建仓库

访问：https://github.com/new

- 仓库名称：`scan-code`
- 描述：二维码扫码防错系统
- 选择 Public 或 Private
- **不要**勾选 "Initialize this repository with a README"
- 点击 "Create repository"
- 复制仓库地址

### 2️⃣ 在 Gitee 创建仓库

访问：https://gitee.com/projects/new

- 仓库名称：`scan-code`
- 描述：二维码扫码防错系统
- 选择 公开 或 私有
- **不要**勾选 "使用 Readme 文件初始化这个仓库"
- 点击 "创建"
- 复制仓库地址

### 3️⃣ 修改推送脚本

编辑 `scripts/git-init-push.sh`，替换第10-11行的仓库地址：

```bash
GITHUB_REPO="https://github.com/YOUR_USERNAME/scan-code.git"
GITEE_REPO="https://gitee.com/YOUR_USERNAME/scan-code.git"
```

替换为你的实际仓库地址，例如：

```bash
GITHUB_REPO="https://github.com/zhangsan/scan-code.git"
GITEE_REPO="https://gitee.com/zhangsan/scan-code.git"
```

### 4️⃣ 运行推送脚本

```bash
./scripts/git-init-push.sh
```

按提示操作即可！

---

## 🔐 认证方式

### 使用 HTTPS（推荐）

推送时会要求输入用户名和密码：
- 用户名：你的 GitHub/Gitee 用户名
- 密码：使用 **Personal Access Token**（不是登录密码）

**获取 Token：**

**GitHub:**
1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. 勾选 `repo` 权限
4. 生成并复制 token
5. 推送时使用 token 作为密码

**Gitee:**
1. 访问 https://gitee.com/profile/personal_access_tokens
2. 点击 "生成新令牌"
3. 勾选 `projects` 权限
4. 生成并复制令牌
5. 推送时使用令牌作为密码

### 使用 SSH（可选）

如果你已经配置了 SSH 密钥，可以使用 SSH 地址：

```bash
GITHUB_REPO="git@github.com:YOUR_USERNAME/scan-code.git"
GITEE_REPO="git@gitee.com:YOUR_USERNAME/scan-code.git"
```

---

## ✅ 推送成功后

访问你的仓库查看代码：
- GitHub: `https://github.com/YOUR_USERNAME/scan-code`
- Gitee: `https://gitee.com/YOUR_USERNAME/scan-code`

---

## 🔄 后续更新

```bash
# 1. 修改代码后
git add .
git commit -m "feat: 新功能"

# 2. 推送到 GitHub
git push origin main

# 3. 推送到 Gitee
git push gitee main

# 或一次推送到所有仓库
git push --all
```

---

## 📚 详细文档

查看完整的 Git 使用指南：[docs/GIT_GUIDE.md](GIT_GUIDE.md)

---

**需要帮助？** 查看 [常见问题](GIT_GUIDE.md#常见问题)
