# Environment Setup

换机器时一键安装开发环境：Clash、Git、Claude Code、Codex CLI。

## 目录

- [安装的工具](#安装的工具)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [命令选项](#命令选项)
- [工作流程](#工作流程)
- [支持的发行版](#支持的发行版)
- [项目结构](#项目结构)
- [常见问题](#常见问题)

## 安装的工具

| 工具 | 用途 | 安装方式 | 依赖 |
|------|------|----------|------|
| **Node.js + NVM** | JavaScript 运行时，nvm 管理多版本 | `curl` 安装 nvm → `nvm install` | curl |
| **Git** | 版本控制 + 全局配置 | 系统包管理器 | 无 |
| **Clash** | 代理/VPN（mihomo 内核） | 封装 [clash-for-linux](https://github.com/wnlen/clash-for-linux) | curl, wget, xz-utils |
| **Claude Code** | Anthropic AI 命令行工具 | `npm install -g` | Node.js |
| **Codex** | OpenAI 命令行工具 | `npm install -g` | Node.js |

## 快速开始

```bash
# 1. 进入项目目录
cd /path/to/setup

# 2. 编辑配置文件（可选，按需修改）
vim config

# 3. 一键安装
bash setup.sh
```

首次运行大约需要 3-5 分钟（取决于网络速度）。后续运行会自动跳过已安装的工具。

## 配置说明

编辑 `config` 文件自定义安装行为：

### 模块开关

```bash
# 设为 false 跳过对应模块
INSTALL_NODE=true      # Node.js + NVM
INSTALL_GIT=true       # Git
INSTALL_CLASH=true     # Clash 代理
INSTALL_CLAUDE=true    # Claude Code
INSTALL_CODEX=true     # Codex CLI
```

### Git 全局设置

```bash
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"
GIT_DEFAULT_BRANCH="main"
```

仅在 Git 首次安装时设置，已有配置不会被覆盖。

### Clash 设置

```bash
# 机场订阅链接（留空则手动导入）
CLASH_SUBSCRIBE_URL="https://your-subscription-url"

# 内核: mihomo（推荐）或 clash
CLASH_KERNEL="mihomo"

# 安装路径，默认 ~/clashctl
CLASH_BASE_DIR="$HOME/clashctl"

# GitHub 加速代理（国内用户）
GH_PROXY=""
```

Clash 安装完成后，使用 `clashon` / `clashoff` 开关代理。

### Node.js 设置

```bash
# Node 版本: lts/*, 20, 18, 等
NODE_VERSION="lts/*"

# npm 镜像（国内用户）
NPM_REGISTRY_MIRROR="https://registry.npmmirror.com"
```

## 命令选项

```bash
bash setup.sh              # 安装所有启用的模块（跳过已安装）
bash setup.sh --force      # 忽略缓存，强制重装全部模块
bash setup.sh -f           # 同上，简写
```

## 工作流程

```
┌─────────────────────────────────┐
│  setup.sh 入口                   │
│  1. 加载 common.sh + config      │
│  2. 检测 OS 和包管理器           │
│  3. 初始化状态目录 ~/.local/...  │
└──────────┬──────────────────────┘
           │
           ▼
     ┌──────────┐
     │  node.sh │ ← 为 claude/codex 提供 Node 环境
     └────┬─────┘
          ▼
     ┌──────────┐
     │  git.sh  │
     └────┬─────┘
          ▼
     ┌──────────┐
     │ clash.sh │ ← 修改 .env → 调用已有安装器
     └────┬─────┘
          ▼
     ┌──────────┐
     │claude.sh │ ← npm install -g
     └────┬─────┘
          ▼
     ┌──────────┐
     │ codex.sh │ ← npm install -g
     └────┬─────┘
          ▼
     打印安装摘要
```

每个模块独立执行，某个失败不影响后续模块。

### 幂等机制

- **标记文件**: 安装成功后创建 `~/.local/state/env-setup/<module>.installed`
- **命令检测**: 即使无标记，也会检查命令是否已在 PATH
- **安全重跑**: 多次运行只会有一次实际安装

```bash
# 第一次运行：全部安装
bash setup.sh

# 第二次运行：全部跳过
bash setup.sh
# [SKIP] node 已安装（标记检测），跳过
# [SKIP] git 已安装（标记检测），跳过
# ...
```

## 支持的发行版

脚本自动检测 `/etc/os-release` 选择正确的包管理器：

| 发行版 | 包管理器 | 状态 |
|--------|----------|------|
| Ubuntu / Debian / Mint | `apt` | ✅ |
| Fedora / RHEL / CentOS / Rocky | `dnf` / `yum` | ✅ |
| Arch / Manjaro / EndeavourOS | `pacman` | ✅ |
| openSUSE | `zypper` | ✅ |
| Alpine | `apk` | ✅ |

nvm、Node.js、Claude Code、Codex 安装方式在所有发行版上一致，无需特殊处理。

## 项目结构

```
setup/
├── setup.sh                          # 入口脚本
├── config                             # 用户配置文件
├── modules/
│   ├── common.sh                      # 公共库：日志、OS 检测、包管理器、幂等标记
│   ├── node.sh                        # NVM + Node.js 安装
│   ├── git.sh                         # Git 安装 + 全局配置
│   ├── clash.sh                       # Clash 安装（封装已有安装器）
│   ├── claude.sh                      # Claude Code（npm global）
│   └── codex.sh                       # Codex CLI（npm global）
├── clash-for-linux-install-master/    # Clash 安装器（不直接修改）
│   ├── install.sh                     #   原始安装脚本
│   ├── .env                           #   内核/路径/代理等配置
│   └── resources/                     #   UI 和内核资源
└── README.md
```

## 常见问题

### Q: 如何只安装部分工具？

在 `config` 中将不需要的工具设为 `false`：

```bash
INSTALL_CLASH=false
INSTALL_CODEX=false
```

然后正常运行 `bash setup.sh`。

### Q: 安装 Clash 后如何配置代理？

```bash
# 开启代理
clashon

# 关闭代理
clashoff

# 查看状态
clashctl status
```

### Q: 如何在多台机器间同步配置？

将整个 `setup/` 目录推送到 Git 仓库：

```bash
git init
git add -A
git commit -m "init env setup"
git remote add origin <your-repo-url>
git push -u origin main
```

在新机器上：

```bash
git clone <your-repo-url> setup
cd setup
# 编辑 config 填好订阅链接
bash setup.sh
```

### Q: Node 安装了但 claude/codex 报 command not found？

nvm 安装的全局包需要 nvm 环境已加载。确认 `~/.bashrc` 或 `~/.zshrc` 中有：

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

开新终端或执行 `source ~/.bashrc` 后即可。

### Q: 国内网络慢怎么办？

在 `config` 中设置镜像：

```bash
GH_PROXY="https://gh-proxy.com/"
NPM_REGISTRY_MIRROR="https://registry.npmmirror.com"
```
