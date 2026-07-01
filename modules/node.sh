#!/usr/bin/env bash
# node.sh — NVM + Node.js 安装模块

# ============================================================
# 依赖：common.sh 需先被 source
# ============================================================

# NVM 安装脚本地址（不用 readonly，避免与 nvm.sh 内部变量冲突）
NVM_VERSION="v0.40.1"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
NVM_GITEE_REPO="https://gitee.com/mirrors/nvm.git"

# 尝试下载 URL，支持自动 fallback
# 用法: fetch_url <url> [fallback_url]
_fetch() {
    local url=$1
    local fallback=${2:-}

    # 先直连尝试，设置较短超时
    if curl -fsSL --connect-timeout 5 --max-time 30 "$url" 2>/dev/null; then
        return 0
    fi

    # 直连失败，尝试通过 github 代理
    if [ -n "$fallback" ]; then
        log_warn "直连失败，尝试代理: $fallback"
        if curl -fsSL --connect-timeout 10 --max-time 60 "$fallback" 2>/dev/null; then
            return 0
        fi
    fi

    # 如果有 GH_PROXY，尝试用它
    if [ -n "${GH_PROXY:-}" ]; then
        local proxy_url="${GH_PROXY%/}/${url}"
        log_warn "尝试 GitHub 代理: $proxy_url"
        if curl -fsSL --connect-timeout 10 --max-time 60 "$proxy_url" 2>/dev/null; then
            return 0
        fi
    fi

    return 1
}

install_node() {
    if [ -z "${NVM_DIR:-}" ]; then
        export NVM_DIR="$HOME/.nvm"
    fi

    # 1. 安装 nvm
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        log_skip "NVM 已安装: $NVM_DIR"
    else
        log_info "正在安装 NVM (${NVM_VERSION}) ..."

        # 安装依赖
        if ! cmd_exists curl; then
            pkg_install curl
        fi
        if ! cmd_exists git; then
            pkg_install git
        fi

        local installed=false

        # 方式 1: 通过 gitee 镜像 git clone（国内最可靠）
        log_info "尝试从 Gitee 镜像安装 NVM ..."
        if git clone --depth 1 "$NVM_GITEE_REPO" "$NVM_DIR" 2>/dev/null; then
            log_success "NVM 安装完成（Gitee 镜像）"
            installed=true
        fi

        # 方式 2: 通过 gh-proxy 下载官方安装脚本
        if ! $installed; then
            log_info "尝试从 GitHub 代理安装 NVM ..."
            local proxy_install_url="${GH_PROXY%/}/${NVM_INSTALL_URL}"
            if _fetch "$NVM_INSTALL_URL" "$proxy_install_url" | bash 2>/dev/null; then
                log_success "NVM 安装完成（代理）"
                installed=true
            fi
        fi

        # 方式 3: 直连 GitHub（海外用户）
        if ! $installed; then
            log_info "尝试直连 GitHub 安装 NVM ..."
            if curl -fsSL --connect-timeout 10 --max-time 60 "$NVM_INSTALL_URL" 2>/dev/null | bash 2>/dev/null; then
                log_success "NVM 安装完成（直连）"
                installed=true
            fi
        fi

        if ! $installed; then
            log_error "NVM 安装失败，请检查网络"
            return 1
        fi
    fi

    # 2. 加载 nvm
    load_nvm

    if ! cmd_exists nvm && ! type nvm &>/dev/null 2>&1; then
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            . "$NVM_DIR/nvm.sh"
        fi
    fi

    # 3. 设置 Node.js 下载镜像（国内加速）
    if [ -n "${NODE_MIRROR:-}" ]; then
        export NVM_NODEJS_ORG_MIRROR="$NODE_MIRROR"
        log_info "Node 镜像: $NODE_MIRROR"
    fi

    # 4. 安装 Node.js
    local node_version="${NODE_VERSION:-lts/*}"

    if cmd_exists node; then
        log_skip "Node.js $(node --version) 已安装"
    else
        log_info "正在安装 Node.js $node_version ..."
        nvm install "$node_version"
        nvm alias default "$node_version"
        nvm use default
        log_success "Node.js $(node --version) 安装完成"
    fi

    # 5. 配置 npm 镜像
    if [ -n "${NPM_REGISTRY_MIRROR:-}" ]; then
        log_info "设置 npm registry: $NPM_REGISTRY_MIRROR"
        npm config set registry "$NPM_REGISTRY_MIRROR"
    fi

    return 0
}

verify_node() {
    cmd_exists node && cmd_exists npm
}
