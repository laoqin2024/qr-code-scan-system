#!/bin/bash

# 二维码扫码防错系统 - Git 初始化和推送脚本
# 使用前请先在 GitHub 和 Gitee 上创建仓库

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Git 初始化和推送脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 请替换为你的仓库地址
GITHUB_REPO="git@github.com:laoqin2024/qr-code-scan-system.git"
GITEE_REPO="https://gitee.com/laoqin1/qr-code-scan-system.git"

echo ""
echo "⚠️  请先确认："
echo "1. 已在 GitHub 创建仓库"
echo "2. 已在 Gitee 创建仓库"
echo "3. 已修改本脚本中的仓库地址"
echo ""
read -p "确认继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "已取消"
    exit 1
fi

# 检查是否已经是 Git 仓库
if [ -d .git ]; then
    echo "✅ 已存在 Git 仓库"
else
    echo "📝 初始化 Git 仓库..."
    git init
    echo "✅ Git 仓库初始化完成"
fi

# 添加所有文件
echo ""
echo "📝 添加文件到暂存区..."
git add .

# 检查是否有文件被添加
if git diff --cached --quiet; then
    echo "⚠️  没有文件需要提交"
else
    echo "✅ 文件已添加到暂存区"
    
    # 显示将要提交的文件
    echo ""
    echo "将要提交的文件："
    git status --short
fi

# 提交
echo ""
echo "📝 提交更改..."
git commit -m "feat: 初始提交 - 二维码扫码防错系统 v5.0

功能特性：
- ✅ 二维码扫码录入（支持扫码枪）
- ✅ 实时长度验证
- ✅ 多客户、多产品管理
- ✅ 细粒度权限控制
- ✅ 扫码记录查询与导出
- ✅ 审计日志追踪
- ✅ 系统管理功能

技术栈：
- 前端：React 18 + TypeScript + Vite
- 后端：Node.js + Express + TypeScript
- 数据库：SQLite

版本：v5.0
日期：2025-01-06"

if [ $? -eq 0 ]; then
    echo "✅ 提交成功"
else
    echo "❌ 提交失败"
    exit 1
fi

# 添加远程仓库
echo ""
echo "📝 添加远程仓库..."

# 检查是否已存在 origin
if git remote | grep -q "^origin$"; then
    echo "⚠️  远程仓库 origin 已存在，将更新地址"
    git remote set-url origin $GITHUB_REPO
else
    git remote add origin $GITHUB_REPO
fi
echo "✅ GitHub 远程仓库已添加: $GITHUB_REPO"

# 检查是否已存在 gitee
if git remote | grep -q "^gitee$"; then
    echo "⚠️  远程仓库 gitee 已存在，将更新地址"
    git remote set-url gitee $GITEE_REPO
else
    git remote add gitee $GITEE_REPO
fi
echo "✅ Gitee 远程仓库已添加: $GITEE_REPO"

# 显示远程仓库
echo ""
echo "远程仓库列表："
git remote -v

# 推送到 GitHub
echo ""
echo "📝 推送到 GitHub..."
git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo "✅ 推送到 GitHub 成功"
else
    echo "❌ 推送到 GitHub 失败"
    echo "可能的原因："
    echo "1. 仓库地址错误"
    echo "2. 没有权限"
    echo "3. 需要配置 SSH 密钥或 Personal Access Token"
fi

# 推送到 Gitee
echo ""
echo "📝 推送到 Gitee..."
git push -u gitee main

if [ $? -eq 0 ]; then
    echo "✅ 推送到 Gitee 成功"
else
    echo "❌ 推送到 Gitee 失败"
    echo "可能的原因："
    echo "1. 仓库地址错误"
    echo "2. 没有权限"
    echo "3. 需要配置 SSH 密钥或 Personal Access Token"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Git 初始化和推送完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 后续操作："
echo "1. 访问 GitHub 仓库查看代码"
echo "2. 访问 Gitee 仓库查看代码"
echo "3. 配置仓库描述和标签"
echo "4. 添加 LICENSE 文件（如需要）"
echo ""
echo "🔄 后续推送命令："
echo "  git add ."
echo "  git commit -m \"feat: 新功能\""
echo "  git push origin main    # 推送到 GitHub"
echo "  git push gitee main     # 推送到 Gitee"
echo "  git push --all          # 推送到所有远程仓库"
echo ""
