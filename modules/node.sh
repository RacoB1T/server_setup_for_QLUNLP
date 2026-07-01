#!/usr/bin/env bash
# node.sh — NVM + Node.js 安装模块

# ============================================================
# 依赖：common.sh 需先被 source
# ============================================================

install_node() {
    # 1. 安装 nvm
    if [ -z "${NVM_DIR:-}" ]; then
        export NVM_DIR="$HOME/.nvm"
    fi

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        log_skip "NVM 已安装: $NVM_DIR"
    else
        log_info "正在安装 NVM ..."
        # nvm 安装脚本需要 git 和 curl
        if ! cmd_exists curl; then
            pkg_install curl
        fi
        if ! cmd_exists git; then
            pkg_install git
        fi

        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        log_success "NVM 安装完成"
    fi

    # 2. 加载 nvm
    load_nvm

    if ! cmd_exists nvm && ! type nvm &>/dev/null 2>&1; then
        # 尝试手动 source
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            # shellcheck disable=SC1090,SC1091
            . "$NVM_DIR/nvm.sh"
        fi
    fi

    # 3. 安装 Node.js
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

    # 4. 配置 npm 镜像
    if [ -n "${NPM_REGISTRY_MIRROR:-}" ]; then
        log_info "设置 npm registry: $NPM_REGISTRY_MIRROR"
        npm config set registry "$NPM_REGISTRY_MIRROR"
    fi

    return 0
}

verify_node() {
    cmd_exists node && cmd_exists npm
}
