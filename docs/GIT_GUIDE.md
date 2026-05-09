# Git 使用指南

本文档说明如何将项目同步到 GitHub 和 Gitee。

## 📋 前置准备

### 1. 安装 Git

```bash
# macOS
brew install git

# 检查版本
git --version
```

### 2. 配置 Git

```bash
# 配置用户名和邮箱
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 查看配置
git config --list
```

---

## 🚀 快速开始

### 步骤1：创建远程仓库

**GitHub:**
1. 访问 https://github.com/new
2. 仓库名称：`scan-code` 或 `qr-code-scan-system`
3. 描述：二维码扫码防错系统
4. 选择 Public 或 Private
5. **不要**勾选 "Initialize this repository with a README"
6. 点击 "Create repository"
7. 复制仓库地址（HTTPS 或 SSH）

**Gitee:**
1. 访问 https://gitee.com/projects/new
2. 仓库名称：`scan-code` 或 `qr-code-scan-system`
3. 描述：二维码扫码防错系统
4. 选择 公开 或 私有
5. **不要**勾选 "使用 Readme 文件初始化这个仓库"
6. 点击 "创建"
7. 复制仓库地址（HTTPS 或 SSH）

### 步骤2：修改推送脚本

编辑 `scripts/git-init-push.sh`，替换仓库地址：

```bash
# 替换为你的仓库地址
GITHUB_REPO="https://github.com/YOUR_USERNAME/scan-code.git"
GITEE_REPO="https://gitee.com/YOUR_USERNAME/scan-code.git"
```

### 步骤3：运行推送脚本

```bash
# 添加执行权限
chmod +x scripts/git-init-push.sh

# 运行脚本
./scripts/git-init-push.sh
```

---

## 🔐 认证方式

### 方式1：HTTPS（推荐新手）

**优点：** 简单，无需配置  
**缺点：** 每次推送需要输入密码

**使用 Personal Access Token（推荐）：**

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

### 方式2：SSH（推荐熟练用户）

**优点：** 无需每次输入密码  
**缺点：** 需要配置 SSH 密钥

**配置步骤：**

```bash
# 1. 生成 SSH 密钥
ssh-keygen -t ed25519 -C "your.email@example.com"

# 2. 查看公钥
cat ~/.ssh/id_ed25519.pub

# 3. 复制公钥内容

# 4. 添加到 GitHub
# 访问 https://github.com/settings/keys
# 点击 "New SSH key"，粘贴公钥

# 5. 添加到 Gitee
# 访问 https://gitee.com/profile/sshkeys
# 点击 "添加公钥"，粘贴公钥

# 6. 测试连接
ssh -T git@github.com
ssh -T git@gitee.com
```

**使用 SSH 地址：**

```bash
# 修改脚本中的仓库地址为 SSH 格式
GITHUB_REPO="git@github.com:YOUR_USERNAME/scan-code.git"
GITEE_REPO="git@gitee.com:YOUR_USERNAME/scan-code.git"
```

---

## 📝 手动推送步骤

如果不使用脚本，可以手动执行以下命令：

```bash
# 1. 初始化 Git 仓库
git init

# 2. 添加所有文件
git add .

# 3. 提交
git commit -m "feat: 初始提交 - 二维码扫码防错系统 v5.0"

# 4. 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/scan-code.git
git remote add gitee https://gitee.com/YOUR_USERNAME/scan-code.git

# 5. 推送到 GitHub
git branch -M main
git push -u origin main

# 6. 推送到 Gitee
git push -u gitee main
```

---

## 🔄 日常使用

### 提交更改

```bash
# 1. 查看状态
git status

# 2. 添加文件
git add .                    # 添加所有文件
git add file.txt             # 添加指定文件

# 3. 提交
git commit -m "feat: 添加新功能"

# 4. 推送
git push origin main         # 推送到 GitHub
git push gitee main          # 推送到 Gitee
git push --all               # 推送到所有远程仓库
```

### 提交信息规范

```bash
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具

# 示例
git commit -m "feat: 添加审计日志功能"
git commit -m "fix: 修复权限检查bug"
git commit -m "docs: 更新README文档"
```

### 查看历史

```bash
# 查看提交历史
git log

# 简洁模式
git log --oneline

# 图形化显示
git log --graph --oneline --all
```

### 撤销更改

```bash
# 撤销工作区的修改
git checkout -- file.txt

# 撤销暂存区的修改
git reset HEAD file.txt

# 撤销最后一次提交（保留更改）
git reset --soft HEAD^

# 撤销最后一次提交（丢弃更改）
git reset --hard HEAD^
```

---

## 🌿 分支管理

### 创建和切换分支

```bash
# 创建分支
git branch feature-name

# 切换分支
git checkout feature-name

# 创建并切换（推荐）
git checkout -b feature-name

# 查看所有分支
git branch -a
```

### 合并分支

```bash
# 切换到主分支
git checkout main

# 合并分支
git merge feature-name

# 删除分支
git branch -d feature-name
```

---

## 🔧 常见问题

### 1. 推送失败：认证失败

**问题：** `Authentication failed`

**解决：**
- 使用 Personal Access Token 代替密码
- 或配置 SSH 密钥

### 2. 推送失败：远程仓库有更新

**问题：** `Updates were rejected`

**解决：**
```bash
# 拉取远程更改
git pull origin main --rebase

# 解决冲突（如果有）
# 编辑冲突文件，然后：
git add .
git rebase --continue

# 推送
git push origin main
```

### 3. 忘记添加 .gitignore

**问题：** 已经提交了不该提交的文件

**解决：**
```bash
# 从 Git 中删除但保留本地文件
git rm --cached file.txt
git rm --cached -r node_modules/

# 提交
git commit -m "chore: 更新 .gitignore"

# 推送
git push origin main
```

### 4. 修改最后一次提交

**问题：** 提交信息写错了

**解决：**
```bash
# 修改提交信息
git commit --amend -m "新的提交信息"

# 强制推送（谨慎使用）
git push origin main --force
```

### 5. 同步到多个远程仓库

**方法1：分别推送**
```bash
git push origin main
git push gitee main
```

**方法2：配置 all 远程**
```bash
# 添加 all 远程
git remote add all https://github.com/YOUR_USERNAME/scan-code.git
git remote set-url --add --push all https://github.com/YOUR_USERNAME/scan-code.git
git remote set-url --add --push all https://gitee.com/YOUR_USERNAME/scan-code.git

# 一次推送到所有仓库
git push all main
```

---

## 📚 推荐资源

### 学习资源
- [Git 官方文档](https://git-scm.com/doc)
- [GitHub 文档](https://docs.github.com/)
- [Gitee 帮助中心](https://gitee.com/help)
- [Pro Git 中文版](https://git-scm.com/book/zh/v2)

### GUI 工具
- [GitHub Desktop](https://desktop.github.com/)
- [SourceTree](https://www.sourcetreeapp.com/)
- [GitKraken](https://www.gitkraken.com/)
- [VS Code Git 插件](https://code.visualstudio.com/docs/editor/versioncontrol)

---

## 🎯 最佳实践

### 1. 提交频率
- 小步提交，频繁提交
- 每个提交只做一件事
- 提交前测试代码

### 2. 提交信息
- 使用规范的提交信息格式
- 简洁明了，说明做了什么
- 必要时添加详细描述

### 3. 分支策略
- main/master：生产分支
- develop：开发分支
- feature/*：功能分支
- hotfix/*：紧急修复分支

### 4. 代码审查
- 使用 Pull Request
- 代码审查后再合并
- 保持代码质量

---

**最后更新：** 2025-01-06  
**版本：** v5.0
