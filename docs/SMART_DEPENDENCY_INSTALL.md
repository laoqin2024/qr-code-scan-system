# 智能依赖安装功能更新

## 版本 v5.2.0

**更新时间：** 2025-01-06

---

## 🎯 新增功能

### 系统版本自动检测

部署脚本现在会自动检测系统版本，并根据不同版本安装相应的依赖包。

---

## 🔍 检测内容

### 1. Ubuntu 版本检测

**Ubuntu 22.04+（新版本）：**
```bash
系统: Ubuntu 22.04
安装 Python setuptools (Ubuntu 22.04+)...
sudo apt-get install -y python3-pip python3-setuptools
```

**Ubuntu 20.04 及以下（旧版本）：**
```bash
系统: Ubuntu 20.04
安装 Python distutils (Ubuntu 20.04-)...
sudo apt-get install -y python3-distutils python3-pip
```

### 2. CentOS/RHEL 版本检测

**CentOS 8+ / RHEL 8+（使用 dnf）：**
```bash
系统: CentOS Stream 8
RHEL/CentOS 版本: 8
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y python3 python3-devel python3-pip
```

**CentOS 7 / RHEL 7（使用 yum）：**
```bash
系统: CentOS 7
RHEL/CentOS 版本: 7
sudo yum groupinstall -y "Development Tools"
sudo yum install -y python3 python3-devel python3-pip
```

### 3. Debian 版本检测

**自动尝试两种方式：**
```bash
系统: Debian 11
安装 Python 依赖...
# 先尝试 distutils，失败则使用 setuptools
sudo apt-get install -y python3-distutils || \
sudo apt-get install -y python3-pip python3-setuptools
```

### 4. macOS 版本检测

```bash
系统: macOS 14.0
检测到 macOS 系统
```

---

## 📊 支持的系统版本

### Ubuntu

| 版本 | 支持 | Python 包 |
|------|------|-----------|
| Ubuntu 24.04 | ✅ | python3-setuptools |
| Ubuntu 22.04 | ✅ | python3-setuptools |
| Ubuntu 20.04 | ✅ | python3-distutils |
| Ubuntu 18.04 | ✅ | python3-distutils |

### Debian

| 版本 | 支持 | Python 包 |
|------|------|-----------|
| Debian 12 | ✅ | python3-setuptools |
| Debian 11 | ✅ | 自动检测 |
| Debian 10 | ✅ | python3-distutils |

### CentOS/RHEL

| 版本 | 支持 | 包管理器 |
|------|------|----------|
| CentOS Stream 9 | ✅ | dnf |
| CentOS Stream 8 | ✅ | dnf |
| CentOS 7 | ✅ | yum |
| RHEL 9 | ✅ | dnf |
| RHEL 8 | ✅ | dnf |
| RHEL 7 | ✅ | yum |

### macOS

| 版本 | 支持 | 要求 |
|------|------|------|
| macOS 14+ | ✅ | Homebrew |
| macOS 13 | ✅ | Homebrew |
| macOS 12 | ✅ | Homebrew |

---

## 🔧 技术实现

### 版本检测函数

```bash
detect_system_version() {
    if [[ "$OS" == "Linux" ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS_NAME=$NAME
            OS_VERSION=$VERSION_ID
            print_info "系统: $OS_NAME $OS_VERSION"
        fi
    elif [[ "$OS" == "Darwin" ]]; then
        OS_NAME="macOS"
        OS_VERSION=$(sw_vers -productVersion)
        print_info "系统: macOS $OS_VERSION"
    fi
}
```

### 智能安装逻辑

```bash
# Ubuntu 版本判断
if [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    UBUNTU_VERSION=$(echo $OS_VERSION | cut -d. -f1)
    
    if [ "$UBUNTU_VERSION" -ge 22 ]; then
        # Ubuntu 22.04+ 使用 setuptools
        sudo apt-get install -y python3-pip python3-setuptools
    else
        # Ubuntu 20.04 及以下使用 distutils
        sudo apt-get install -y python3-distutils python3-pip
    fi
fi
```

---

## ✅ 优势

### 1. 自动适配

- ✅ 自动检测系统版本
- ✅ 自动选择合适的包
- ✅ 避免安装失败

### 2. 兼容性强

- ✅ 支持多个 Linux 发行版
- ✅ 支持新旧版本
- ✅ 自动降级处理

### 3. 智能容错

- ✅ 安装失败自动尝试替代方案
- ✅ 兼容 yum 和 dnf
- ✅ 不会因为单个包失败而中断

---

## 📝 使用示例

### 示例1：Ubuntu 22.04

```
📋 步骤 3/10: 安装系统依赖
ℹ️  安装编译工具和依赖...
ℹ️  系统: Ubuntu 22.04
ℹ️  检测到 Debian/Ubuntu 系统
ℹ️  安装编译工具...
ℹ️  Ubuntu 版本: 22
ℹ️  安装 Python setuptools (Ubuntu 22.04+)...
✅ 系统依赖安装完成
```

### 示例2：Ubuntu 20.04

```
📋 步骤 3/10: 安装系统依赖
ℹ️  安装编译工具和依赖...
ℹ️  系统: Ubuntu 20.04
ℹ️  检测到 Debian/Ubuntu 系统
ℹ️  安装编译工具...
ℹ️  Ubuntu 版本: 20
ℹ️  安装 Python distutils (Ubuntu 20.04-)...
✅ 系统依赖安装完成
```

### 示例3：CentOS 8

```
📋 步骤 3/10: 安装系统依赖
ℹ️  安装编译工具和依赖...
ℹ️  系统: CentOS Stream 8
ℹ️  检测到 CentOS/RHEL 系统
ℹ️  RHEL/CentOS 版本: 8
ℹ️  安装编译工具...
✅ 系统依赖安装完成
```

---

## 🔄 升级指南

### 获取最新版本

```bash
# 一键部署（自动使用最新版本）
bash <(curl -fsSL https://gitee.com/laoqin1/qr-code-scan-system/raw/main/scripts/deploy.sh)

# 或更新现有项目
cd /path/to/scan-code
git pull origin main
./scripts/deploy.sh
```

---

## 🐛 故障排查

### 如果仍然遇到依赖问题

**手动安装依赖：**

**Ubuntu 22.04+:**
```bash
sudo apt-get update
sudo apt-get install -y build-essential python3 python3-dev python3-pip python3-setuptools
```

**Ubuntu 20.04:**
```bash
sudo apt-get update
sudo apt-get install -y build-essential python3 python3-dev python3-distutils python3-pip
```

**CentOS 8+:**
```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y python3 python3-devel python3-pip
```

**CentOS 7:**
```bash
sudo yum groupinstall -y "Development Tools"
sudo yum install -y python3 python3-devel python3-pip
```

---

## 📚 相关文档

- **部署指南：** `docs/DEPLOYMENT_GUIDE.md`
- **故障排查：** `docs/TROUBLESHOOTING.md`
- **快速部署：** `DEPLOY.md`

---

**更新完成时间：** 2025-01-06  
**版本：** v5.2.0  
**状态：** ✅ 已发布
