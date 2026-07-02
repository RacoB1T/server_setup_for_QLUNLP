# Environment Setup

分配新的docker时一键安装开发环境：gcc、tmux、Clash、Git、Claude Code、Codex CLI。

**默认配置国内可直接使用，无需开启代理。**

## 目录

- [安装的工具](#安装的工具)
- [快速开始](#快速开始)
- [国内网络支持](#国内网络支持)
- [配置说明](#配置说明)
- [命令选项](#命令选项)
- [工作流程](#工作流程)
- [支持的发行版](#支持的发行版)
- [项目结构](#项目结构)
- [Clash 使用参考](#clash-使用参考)
- [常见问题](#常见问题)

## 安装的工具

| 工具 | 用途 | 安装方式 | 依赖 |
|------|------|----------|------|
| **GCC / G++** | C/C++ 编译工具链 | 系统包管理器 | 无 |
| **tmux** | 终端复用器 | 系统包管理器 | 无 |
| **Node.js + NVM** | JavaScript 运行时，nvm 管理多版本 | Gitee 镜像 → gh-proxy 兜底 | curl, git |
| **Git** | 版本控制 + 全局配置 | 系统包管理器 | 无 |
| **Clash** | 代理/VPN（mihomo 内核） | 封装 clash-for-linux 安装器，走 gh-proxy | curl, wget, xz-utils |
| **Claude Code** | Anthropic AI 命令行工具 | `npm install -g`（走 npmmirror） | Node.js |
| **Codex** | OpenAI 命令行工具 | `npm install -g`（走 npmmirror） | Node.js |

## 快速开始

```bash
cd /path/to/setup

# 编辑配置（可选）
vim config

# 一键安装
bash setup.sh
```

首次运行约 3-5 分钟（取决于网络）。后续运行自动跳过已安装的工具。

## 国内网络支持

所有下载源已针对国内网络优化，**无需开启代理即可使用**：

| 下载源 | 默认地址 | 说明 |
|--------|----------|------|
| NVM 安装脚本 | Gitee 镜像 | `gitee.com/mirrors/nvm.git` |
| NVM 安装兜底 | gh-proxy → GitHub 直连 | 镜像不可用时自动切换 |
| Node.js 二进制 | npmmirror | `npmmirror.com/mirrors/node` |
| npm 包（Claude/Codex） | npmmirror | `registry.npmmirror.com` |
| Clash 内核/组件 | gh-proxy 代理 GitHub | `gh-proxy.com` → GitHub Releases |

**海外用户**：在 `config` 中将镜像清空即可走官方源：

```bash
GH_PROXY=""
NPM_REGISTRY_MIRROR=""
NODE_MIRROR=""
```

NVM 会自动 fallback 到 GitHub 直连。

## 配置说明

编辑 `config` 文件自定义安装行为。

### 模块开关

```bash
INSTALL_GCC=true       # GCC/G++ 编译工具链
INSTALL_NODE=true      # Node.js + NVM（claude/codex 的前置依赖）
INSTALL_GIT=true       # Git
INSTALL_CLASH=true     # Clash 代理
INSTALL_CLAUDE=true    # Claude Code
INSTALL_CODEX=true     # Codex CLI
```

设为 `false` 跳过对应模块。

### Git 全局设置

```bash
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"
GIT_DEFAULT_BRANCH="main"
```

仅 Git 首次安装时生效，已有配置不会被覆盖。

### Clash 设置

```bash
# 机场订阅链接（留空则手动导入）
CLASH_SUBSCRIBE_URL="https://your-subscription-url"

# 内核: mihomo（推荐）或 clash
CLASH_KERNEL="mihomo"

# 安装路径
CLASH_BASE_DIR="$HOME/clashctl"

# GitHub 代理（国内默认 gh-proxy，海外可清空）
GH_PROXY="https://gh-proxy.com/"
```

安装后使用 `clashon` / `clashoff` 开关代理。

### Node.js 设置

```bash
# Node 版本: lts/*, 20, 18 等
NODE_VERSION="lts/*"

# npm 镜像（国内默认 npmmirror，海外可清空）
NPM_REGISTRY_MIRROR="https://registry.npmmirror.com"

# Node 二进制镜像（nvm 下载 node 时使用）
NODE_MIRROR="https://npmmirror.com/mirrors/node"
```

## 命令选项

```bash
bash setup.sh              # 安装所有启用的模块（跳过已安装）
bash setup.sh --force      # 忽略缓存，强制重装全部
bash setup.sh -f           # --force 简写
```

## 工作流程

```
setup.sh 入口
  │
  ├─ 1. 加载 common.sh + config
  ├─ 2. 检测 OS 和包管理器
  ├─ 3. 初始化状态目录
  │
  ├─ gcc.sh     ← 系统包管理器
  ├─ tmux.sh    ← 系统包管理器
  ├─ node.sh    ← NVM (Gitee → gh-proxy → 直连)
  │                 ↓ 设 NVM_NODEJS_ORG_MIRROR
  │                 ↓ nvm install node
  │                 ↓ npm config set registry
  ├─ git.sh     ← 系统包管理器
  ├─ clash.sh   ← 修改 .env → 调用已有安装器 (gh-proxy)
  ├─ claude.sh  ← npm install -g (npmmirror)
  ├─ codex.sh   ← npm install -g (npmmirror)
  │
  └─ 打印安装摘要
```

每个模块独立执行，某个失败不影响后续模块。NVM 安装有三级 fallback：

```
Gitee 镜像 (git clone)  →  gh-proxy (curl pipe bash)  →  GitHub 直连
     ↓ 国内最可靠                ↓ 备选                       ↓ 海外用户
```

### 幂等机制

- **标记文件**：安装成功后创建 `~/.local/state/env-setup/<module>.installed`
- **命令检测**：即使无标记，也会检查工具是否已在 PATH
- **安全重跑**：多次运行只会有一次实际安装

```bash
bash setup.sh    # 第一次：全部安装
bash setup.sh    # 第二次：全部 [SKIP]
```

## 支持的发行版

脚本自动检测 `/etc/os-release` 选择包管理器：

| 发行版 | 包管理器 |
|--------|----------|
| Ubuntu / Debian / Mint / Deepin / UOS | `apt` |
| Fedora / RHEL / CentOS / Rocky | `dnf` / `yum` |
| Arch / Manjaro / EndeavourOS | `pacman` |
| openSUSE | `zypper` |
| Alpine | `apk` |

nvm、Node.js、Claude Code、Codex 在所有发行版上安装方式一致。

## 项目结构

```
setup/
├── setup.sh                          # 入口脚本
├── config                             # 用户配置文件
├── modules/
│   ├── common.sh                      # 公共库：日志、OS 检测、包管理器、幂等标记
│   ├── gcc.sh                         # GCC/G++ 编译工具链
│   ├── tmux.sh                        # tmux 终端复用器
│   ├── node.sh                        # NVM + Node.js（三级 fallback）
│   ├── git.sh                         # Git 安装 + 全局配置
│   ├── clash.sh                       # Clash（封装已有安装器，注入 gh-proxy）
│   ├── claude.sh                      # Claude Code（npm global）
│   └── codex.sh                       # Codex CLI（npm global）
├── clash-for-linux-install-master/    # Clash 安装器（不直接修改）
│   ├── install.sh
│   ├── .env                           # 内核/路径/代理 等
│   └── resources/                     # UI 和内核资源
└── README.md
```

## Clash 使用参考

> 以下命令封装自 [clash-for-linux](https://github.com/nelvko/clash-for-linux-install)，更多详情见 [Wiki](https://github.com/nelvko/clash-for-linux-install/wiki/FAQ)。

### 基本操作

```bash
clashon           # 开启代理（同步设置系统代理）
clashoff          # 关闭代理（同步取消系统代理）
clashctl status   # 查看内核运行状态
clashproxy        # 单独控制系统代理开关
```

### Web 控制台

```bash
clashui           # 查看 Web 面板地址（默认端口 9090）
clashsecret       # 查看当前密钥
clashsecret xxx   # 设置新密钥（自动重启生效）
```

可通过浏览器打开控制台进行可视化操作：切换节点、查看日志、测速等。

### 订阅管理

```bash
clashsub add <url>        # 添加订阅（支持本地文件: file:///path）
clashsub ls               # 查看所有订阅
clashsub use <id>         # 切换到指定订阅
clashsub update [id]      # 更新订阅（可选指定 id）
clashsub del <id>         # 删除订阅
clashsub log              # 查看订阅更新日志
```

订阅更新选项：

```bash
clashsub update --auto     # 更新并配置定时自动更新
clashsub update --convert  # 使用本地订阅转换
```

自动更新任务可通过 `crontab -e` 修改。

### Mixin 配置

通过 Mixin 对订阅规则进行自定义，与原始订阅深度合并，Mixin 优先级最高。

```bash
clashmixin       # 查看 Mixin 配置
clashmixin -e    # 编辑 Mixin 配置
clashmixin -c    # 查看原始订阅配置
clashmixin -r    # 查看运行时配置（合并后的最终结果）
```

### Tun 模式

代理本机和 Docker 等容器的全部流量，支持 DNS 劫持。

```bash
clashtun         # 查看 Tun 状态
clashtun on      # 开启 Tun 模式
clashtun off     # 关闭 Tun 模式
```

### 升级内核

```bash
clashupgrade     # 升级 mihomo 内核到最新版本
clashupgrade -v  # 查看详细升级日志
```

### 命令速查

```bash
clashctl COMMAND [OPTIONS]

Commands:
    on              开启代理
    off             关闭代理
    status          内核状况
    proxy           系统代理
    ui              Web 面板
    secret          Web 密钥
    sub             订阅管理
    upgrade         升级内核
    tun             Tun 模式
    mixin           Mixin 配置
```

## 常见问题

### Q: 只需要安装部分工具？

在 `config` 中关闭不需要的模块：

```bash
INSTALL_CLASH=false
INSTALL_CODEX=false
bash setup.sh
```

### Q: 安装 Clash 后怎么用？

详见上方 [Clash 使用参考](#clash-使用参考)。快速上手：

```bash
clashon          # 开启代理
clashoff         # 关闭代理
```

### Q: 如何在多台机器间同步配置？

```bash
# 在已有机器上
cd setup
git init && git add -A && git commit -m "init"
git remote add origin <your-repo>
git push -u origin main

# 在新机器上
git clone <your-repo> setup
cd setup
vim config   # 填好订阅链接
bash setup.sh
```

### Q: Node 装了但 claude/codex 报 command not found？

nvm 全局包需要 nvm 环境。确认 `~/.bashrc` 中有：

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

开新终端或 `source ~/.bashrc` 即可。

### Q: 在海外使用，如何切回官方源？

在 `config` 中清空镜像：

```bash
GH_PROXY=""
NPM_REGISTRY_MIRROR=""
NODE_MIRROR=""
```

NVM 会自动 fallback 到 GitHub 直连。

### Q: Gitee / gh-proxy 都挂了怎么办？

手动设置可用的代理或镜像，然后 `bash setup.sh --force` 重试。

### Q: 系统包管理器（apt/dnf）下载慢？

这是系统源的问题，与脚本无关。Ubuntu 用户可先换阿里云/清华源：

```bash
sudo sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
sudo apt update
```
